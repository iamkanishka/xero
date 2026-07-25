defmodule Xero.AppStore do
  @moduledoc """
  Xero App Store API – Subscription and metered billing management.
  Base URL: `https://api.xero.com/appstore/2.0/`
  Grant type: **Client Credentials** (machine-to-machine, no user required).
  Available in: AU, NZ, UK.

  ## Authentication

  Unlike other Xero APIs, the App Store API uses the **Client Credentials** grant.
  Call `client_credentials_token/0` to get a token — no user authorization required.

      {:ok, token} = Xero.AppStore.client_credentials_token()
      {:ok, subs}  = Xero.AppStore.list_subscriptions(token)

  ## Subscription Statuses

  - `"ACTIVE"` — Subscription is active
  - `"CANCELED"` — Subscription has been cancelled
  - `"TRIALING"` — In trial period
  - `"PAST_DUE"` — Payment overdue
  - `"INCOMPLETE"` — Awaiting initial payment

  ## Metered Billing

  For usage-based pricing, call `create_usage_record/4` after each billable event.
  Usage is aggregated per billing period.

      {:ok, _} = Xero.AppStore.create_usage_record(token, subscription_id, plan_id, %{
        "quantity"  => 5.0,
        "timestamp" => "2024-01-15T12:00:00Z",
        "productId" => "api-calls",
        "priceId"   => "per-1000-calls"
      })
  """

  use Xero.API.Base, api: :appstore

  @token_url "https://identity.xero.com/connect/token"

  @doc """
  Obtains a Client Credentials access token for the App Store API.

  This does **not** require a user to authorize — it uses the app's
  `client_id` and `client_secret` directly.

  The token scope is `marketplace.billing`.
  """
  @spec client_credentials_token() :: {:ok, Xero.Auth.Token.t()} | {:error, Error.t()}
  def client_credentials_token do
    config = Xero.Config.get()
    auth = "Basic " <> Base.encode64("#{config[:client_id]}:#{config[:client_secret]}")

    case Client.post_form(
           @token_url,
           %{grant_type: "client_credentials", scope: "marketplace.billing"},
           [{"authorization", auth}]
         ) do
      {:ok, %{status: 200, body: raw}} ->
        {:ok, Token.from_response(Jason.decode!(raw))}

      {:ok, resp} ->
        {:error,
         %Xero.Error{
           type: :oauth_error,
           status: resp.status,
           raw: resp.body,
           message: "Client credentials token request failed"
         }}

      {:error, _} = err ->
        err
    end
  end

  @doc "Lists all subscriptions for your app (all tenants that have subscribed)."
  @spec list_subscriptions(Token.t()) :: {:ok, map()} | {:error, Error.t()}
  def list_subscriptions(%Token{} = t), do: ok_body(req_get(t, nil, "/subscriptions"))

  @doc "Retrieves a single subscription by ID."
  @spec get_subscription(Token.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get_subscription(%Token{} = t, id), do: ok_body(req_get(t, nil, "/subscriptions/#{id}"))

  @doc """
  Creates a usage record for metered billing.

  ## Required fields

  - `"quantity"` — Number of units consumed (float)
  - `"timestamp"` — ISO 8601 UTC timestamp of usage
  - `"productId"` — ID of the metered product from your pricing config
  - `"priceId"` — ID of the price from your pricing config
  """
  @spec create_usage_record(Token.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Error.t()}
  def create_usage_record(%Token{} = t, subscription_id, plan_id, attrs) do
    ok_body(
      post(t, nil, "/subscriptions/#{subscription_id}/plans/#{plan_id}/UsageRecords", attrs)
    )
  end

  @doc "Lists usage records for a subscription plan."
  @spec list_usage_records(Token.t(), String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def list_usage_records(%Token{} = t, subscription_id, plan_id, opts \\ []) do
    params = %{"page" => opts[:page], "pageSize" => opts[:page_size]}

    ok_body(
      req_get(t, nil, "/subscriptions/#{subscription_id}/plans/#{plan_id}/UsageRecords", params)
    )
  end

  @doc "Gets a specific usage record by ID."
  @spec get_usage_record(Token.t(), String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Error.t()}
  def get_usage_record(%Token{} = t, subscription_id, plan_id, usage_record_id) do
    ok_body(
      req_get(
        t,
        nil,
        "/subscriptions/#{subscription_id}/plans/#{plan_id}/UsageRecords/#{usage_record_id}"
      )
    )
  end
end
