# Getting Started with Xero

## Prerequisites

- Elixir 1.18+
- A Xero developer account at [developer.xero.com](https://developer.xero.com/app/manage)

## Step 1 — Create a Xero App

1. Log in at [developer.xero.com/app/manage](https://developer.xero.com/app/manage)
2. Click **New app** → choose **Web app**
3. Set your redirect URI: `https://yourapp.com/auth/xero/callback`
4. Copy your **Client ID** and **Client Secret**

## Step 2 — Install & Configure

```elixir
# mix.exs
{:xero, "~> 0.1"}
```

```elixir
# config/config.exs
config :xero,
  client_id:     System.get_env("XERO_CLIENT_ID"),
  client_secret: System.get_env("XERO_CLIENT_SECRET"),
  redirect_uri:  "https://yourapp.com/auth/xero/callback",
  scopes: ~w(openid profile email offline_access
             accounting.transactions accounting.contacts
             accounting.reports.read assets files projects)
```

## Step 3 — OAuth Flow (Phoenix Example)

```elixir
defmodule MyAppWeb.XeroAuthController do
  use MyAppWeb, :controller

  def authorize(conn, _params) do
    {:ok, url, state} = Xero.Auth.authorize_url()
    conn
    |> put_session(:xero_state, state)
    |> redirect(external: url)
  end

  def callback(conn, %{"code" => code, "state" => state}) do
    stored = get_session(conn, :xero_state)

    if state != stored do
      send_resp(conn, 400, "Invalid state")
    else
      with {:ok, tokens}      <- Xero.Auth.fetch_token(code),
           {:ok, connections} <- Xero.Auth.connections(tokens) do
        tenant = hd(connections)
        user_id = current_user(conn).id
        Xero.Auth.TokenStore.put(user_id, tenant.tenant_id, tokens)
        MyApp.Users.save_xero_tenant(user_id, tenant.tenant_id)
        conn
        |> delete_session(:xero_state)
        |> put_flash(:info, "Connected to Xero: #{tenant.tenant_name}")
        |> redirect(to: ~p"/dashboard")
      end
    end
  end

  def disconnect(conn, _params) do
    user_id   = current_user(conn).id
    tenant_id = MyApp.Users.get_xero_tenant!(user_id)
    {:ok, tokens} = Xero.Auth.TokenStore.get(user_id, tenant_id)
    Xero.Auth.revoke_token(tokens.refresh_token)
    Xero.Auth.TokenStore.delete(user_id, tenant_id)
    conn |> put_flash(:info, "Disconnected") |> redirect(to: ~p"/settings")
  end
end
```

## Step 4 — Making API Calls

```elixir
defmodule MyApp.XeroService do
  def list_authorised_invoices(user_id, tenant_id) do
    with {:ok, tokens} <- Xero.Auth.TokenStore.get(user_id, tenant_id) do
      Xero.Accounting.Invoices.list(tokens, tenant_id,
        statuses: ["AUTHORISED"], page: 1)
    end
  end

  def sync_all_contacts(user_id, tenant_id, last_synced_at) do
    with {:ok, tokens} <- Xero.Auth.TokenStore.get(user_id, tenant_id) do
      Xero.Accounting.Contacts.stream(tokens, tenant_id,
        if_modified_since: last_synced_at)
      |> Stream.each(&MyApp.Contacts.upsert/1)
      |> Stream.run()
    end
  end

  def profit_and_loss_ytd(user_id, tenant_id) do
    year = Date.utc_today().year
    with {:ok, tokens} <- Xero.Auth.TokenStore.get(user_id, tenant_id) do
      Xero.Accounting.Reports.profit_and_loss(tokens, tenant_id,
        from_date: "#{year}-01-01",
        to_date: Date.to_iso8601(Date.utc_today()),
        periods: Date.utc_today().month,
        time_frame: "MONTH")
    end
  end
end
```

## Step 5 — Error Handling

```elixir
case Xero.Accounting.Invoices.list(tokens, tenant_id) do
  {:ok, %{"Invoices" => invoices}} ->
    handle(invoices)

  {:error, %Xero.Error{type: :unauthorized}} ->
    # Token expired and auto-refresh failed — re-auth the user
    redirect_to_xero_login()

  {:error, %Xero.Error{type: :rate_limited, retry_after: n}} ->
    # Automatically handled internally; this is the manual fallback
    Process.sleep(n * 1_000)

  {:error, %Xero.Error{type: :unprocessable, detail: d}} ->
    Logger.error("Validation error: #{inspect(d)}")

  {:error, %Xero.Error{type: :network_error}} ->
    Logger.error("Network connectivity issue")
end
```

## Step 6 — Telemetry

```elixir
# In Application.start/2
:telemetry.attach_many("my-app-xero", [
  [:xero, :http, :request],
  [:xero, :rate_limit, :remaining],
  [:xero, :auth, :token_refreshed],
  [:xero, :auth, :token_refresh_failed]
], &MyApp.XeroTelemetry.handle/4, nil)
```

## Rate Limits

| Limit | Value |
|-------|-------|
| Requests per minute (per tenant) | 60 |
| Requests per day (per tenant) | 5,000 |
| App-wide requests per minute | 10,000 |

The client automatically respects `Retry-After` headers and emits
`[:xero, :rate_limit, :remaining]` telemetry from every response.

## Pagination

```elixir
# Lazy stream (recommended)
Xero.Accounting.Invoices.stream(tokens, tenant_id)
|> Stream.filter(&(&1["Status"] == "AUTHORISED"))
|> Enum.to_list()

# Fetch all pages at once
{:ok, all} = Xero.Paginator.fetch_all(
  fn opts -> Xero.Accounting.Contacts.list(tokens, tenant_id, opts) end,
  key: "Contacts"
)
```

## Incremental Sync

```elixir
last_sync = DateTime.from_iso8601!("2024-01-01T00:00:00Z") |> elem(1)

{:ok, changed} = Xero.Accounting.Invoices.list(tokens, tenant_id,
  if_modified_since: last_sync)
```
