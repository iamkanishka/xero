# Xero

[![Hex.pm](https://img.shields.io/hexpm/v/xero.svg)](https://hex.pm/packages/xero)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/xero)
[![CI](https://github.com/iamkanishka/xero/actions/workflows/ci.yml/badge.svg)](https://github.com/iamkanishka/xero/actions)
[![Coverage](https://coveralls.io/repos/github/iamkanishka/xero/badge.svg?branch=main)](https://coveralls.io/github/iamkanishka/xero)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A **complete, production-grade Elixir client** for all 13 Xero APIs — built with modern Elixir best practices.

---

## Features

| Feature                      | Details                                                                                                                  |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| **All 13 Xero APIs**         | Accounting, Assets, Bank Feeds, Files, Finance, Projects, Payroll AU/NZ/UK, Practice Manager v3.1, App Store, eInvoicing |
| **OAuth 2.0**                | Authorization Code, Client Credentials (App Store), token refresh, CSRF-safe state generation, token revocation          |
| **Multi-tenant token store** | ETS-backed `TokenStore` GenServer with proactive background refresh (5-min pre-expiry)                                   |
| **Connection pooling**       | Finch with configurable pool size and count                                                                              |
| **Rate limit tracking**      | Token-bucket per tenant (60/min, 5 000/day), auto-respects `Retry-After` headers                                         |
| **Pagination**               | `stream/2` (lazy), `fetch_all/2`, single-page helpers; auto-paginates all paginated endpoints                            |
| **Incremental sync**         | `if_modified_since:` on every applicable endpoint                                                                        |
| **Telemetry**                | `[:xero, :http, :request]`, `[:xero, :rate_limit, :remaining]`, auth events                                              |
| **Structured errors**        | Typed `Xero.Error` structs — never raw maps                                                                              |
| **Validated config**         | NimbleOptions schema with full documentation                                                                             |
| **Type constants**           | `Xero.Types` — all status codes, enumerations, tax types for AU/NZ/UK/US                                                 |

---

## Installation

```elixir
# mix.exs
def deps do
  [
    {:xero, "~> 0.1"}
  ]
end
```

---

## Configuration

```elixir
# config/config.exs
config :xero,
  client_id:     System.get_env("XERO_CLIENT_ID"),
  client_secret: System.get_env("XERO_CLIENT_SECRET"),
  redirect_uri:  "https://yourapp.com/auth/xero/callback",
  scopes: ~w(
    openid profile email offline_access
    accounting.transactions
    accounting.contacts
    accounting.reports.read
    accounting.settings
    accounting.attachments
    accounting.budgets.read
    assets files projects
  )
```

### All Configuration Options

| Key                | Type       | Default       | Description                                      |
| ------------------ | ---------- | ------------- | ------------------------------------------------ |
| `client_id`        | string     | **required**  | Xero app Client ID                               |
| `client_secret`    | string     | **required**  | Xero app Client Secret                           |
| `redirect_uri`     | string     | **required**  | OAuth callback URL                               |
| `scopes`           | `[string]` | `[openid, …]` | OAuth2 scopes                                    |
| `timeout`          | integer    | `30_000`      | Request timeout ms                               |
| `connect_timeout`  | integer    | `10_000`      | TCP connect timeout ms                           |
| `pool_size`        | integer    | `10`          | Finch pool size                                  |
| `pool_count`       | integer    | `4`           | Finch pool count                                 |
| `max_retries`      | integer    | `3`           | Retry attempts                                   |
| `retry_base_delay` | integer    | `1_000`       | Backoff base ms                                  |
| `retry_max_delay`  | integer    | `30_000`      | Backoff cap ms                                   |
| `log_level`        | atom       | `:info`       | `:debug \| :info \| :warning \| :error \| :none` |

---

## Quick Start

```elixir
# 1. Generate the OAuth authorization URL
{:ok, url, state} = Xero.Auth.authorize_url()
# → store state in session, redirect user to url

# 2. Exchange code for tokens (in your OAuth callback handler)
{:ok, tokens} = Xero.Auth.fetch_token(params["code"])

# 3. List connected Xero organisations
{:ok, [tenant | _]} = Xero.Auth.connections(tokens)

# 4. Store tokens (auto-refreshed when retrieved)
Xero.Auth.TokenStore.put(user_id, tenant.tenant_id, tokens)

# 5. Use any API
{:ok, tokens} = Xero.Auth.TokenStore.get(user_id, tenant.tenant_id)

{:ok, result} = Xero.Accounting.Invoices.list(tokens, tenant.tenant_id,
  statuses: ["AUTHORISED"], page: 1)

{:ok, _} = Xero.Accounting.Invoices.create(tokens, tenant.tenant_id, %{
  "Type"    => "ACCREC",
  "Contact" => %{"ContactID" => "contact-uuid"},
  "LineItems" => [%{
    "Description" => "Consulting",
    "Quantity"    => 1.0,
    "UnitAmount"  => 500.0,
    "AccountCode" => "200"
  }],
  "Status"  => "AUTHORISED"
})
```

---

## All Supported APIs

| Module                               | API                   | Notes                                                  |
| ------------------------------------ | --------------------- | ------------------------------------------------------ |
| `Xero.Accounting.Invoices`           | Invoices              | CRUD, email, PDF, stream, online URL, history          |
| `Xero.Accounting.Contacts`           | Contacts              | CRUD, stream, CIS (UK), history                        |
| `Xero.Accounting.Accounts`           | Chart of Accounts     | CRUD, archive                                          |
| `Xero.Accounting.Payments`           | Payments              | Multi-currency, stream                                 |
| `Xero.Accounting.BankTransactions`   | Bank Transactions     | stream                                                 |
| `Xero.Accounting.BankTransfers`      | Bank Transfers        | —                                                      |
| `Xero.Accounting.BatchPayments`      | Batch Payments        | —                                                      |
| `Xero.Accounting.CreditNotes`        | Credit Notes          | Allocations                                            |
| `Xero.Accounting.Overpayments`       | Overpayments          | Allocations                                            |
| `Xero.Accounting.Prepayments`        | Prepayments           | Allocations                                            |
| `Xero.Accounting.PurchaseOrders`     | Purchase Orders       | PDF, stream                                            |
| `Xero.Accounting.Quotes`             | Quotes                | —                                                      |
| `Xero.Accounting.Items`              | Inventory             | Tracked & untracked                                    |
| `Xero.Accounting.ManualJournals`     | Manual Journals       | stream                                                 |
| `Xero.Accounting.Journals`           | Journals              | Read-only                                              |
| `Xero.Accounting.LinkedTransactions` | Linked Transactions   | Billable expenses                                      |
| `Xero.Accounting.TaxRates`           | Tax Rates             | —                                                      |
| `Xero.Accounting.TrackingCategories` | Tracking Categories   | Options CRUD                                           |
| `Xero.Accounting.ContactGroups`      | Contact Groups        | Members                                                |
| `Xero.Accounting.Currencies`         | Currencies            | —                                                      |
| `Xero.Accounting.RepeatingInvoices`  | Repeating Invoices    | —                                                      |
| `Xero.Accounting.Organisation`       | Organisation          | Actions, CIS                                           |
| `Xero.Accounting.Users`              | Users                 | —                                                      |
| `Xero.Accounting.BrandingThemes`     | Branding Themes       | Payment services                                       |
| `Xero.Accounting.Budgets`            | Budgets               | Requires `accounting.budgets.read`                     |
| `Xero.Accounting.InvoiceReminders`   | Invoice Reminders     | —                                                      |
| `Xero.Accounting.PaymentServices`    | Payment Services      | —                                                      |
| `Xero.Accounting.History`            | History & Notes       | 14 resource types                                      |
| `Xero.Accounting.Reports`            | Reports               | 11 report types                                        |
| `Xero.Assets`                        | Assets API            | Depreciation, asset types                              |
| `Xero.BankFeeds`                     | Bank Feeds API        | ⚠️ Approval required                                   |
| `Xero.Files`                         | Files API             | Upload, folders, associations                          |
| `Xero.Finance`                       | Finance API           | Bank statements, cash validation, financial statements |
| `Xero.Projects`                      | Projects API          | Tasks, time, project items                             |
| `Xero.Payroll.AU`                    | Payroll AU            | Employees, pay runs, timesheets, leave                 |
| `Xero.Payroll.NZ`                    | Payroll NZ            | Employees, pay runs, statutory leave                   |
| `Xero.Payroll.UK`                    | Payroll UK            | HMRC, NI, working patterns                             |
| `Xero.PracticeManager`               | Practice Manager v3.1 | Jobs, clients, staff, time (XML responses)             |
| `Xero.AppStore`                      | App Store API         | Subscriptions, metered billing                         |
| `Xero.EInvoicing`                    | eInvoicing API        | PEPPOL / UBL 2.1, AU & NZ                              |

---

## Error Handling

```elixir
case Xero.Accounting.Invoices.list(tokens, tenant_id) do
  {:ok, %{"Invoices" => invoices}} ->
    handle(invoices)

  {:error, %Xero.Error{type: :unauthorized}} ->
    # Token expired, auto-refresh failed → re-authenticate user
    redirect_to_xero_oauth()

  {:error, %Xero.Error{type: :rate_limited, retry_after: secs}} ->
    # Handled automatically; this is the manual fallback
    Process.sleep(secs * 1_000)

  {:error, %Xero.Error{type: :unprocessable, detail: detail}} ->
    Logger.error("Xero validation failed: #{inspect(detail)}")

  {:error, %Xero.Error{type: :not_found}} ->
    {:error, :resource_not_found}

  {:error, %Xero.Error{type: :network_error, raw: reason}} ->
    Logger.error("Network error: #{inspect(reason)}")
end
```

---

## Pagination

```elixir
# Lazy stream — most efficient, only fetches pages as needed
Xero.Accounting.Invoices.stream(tokens, tenant_id, statuses: ["AUTHORISED"])
|> Stream.filter(&(&1["AmountDue"] > 0))
|> Stream.each(&process_invoice/1)
|> Stream.run()

# Fetch all pages (use with caution on large datasets)
{:ok, all_contacts} = Xero.Paginator.fetch_all(
  fn opts -> Xero.Accounting.Contacts.list(tokens, tenant_id, opts) end,
  key: "Contacts"
)

# Specific page
{:ok, page} = Xero.Accounting.Contacts.list(tokens, tenant_id, page: 3)
```

---

## Incremental Sync

```elixir
last_sync = ~U[2024-01-01 00:00:00Z]

# Only fetches records modified since last_sync
Xero.Accounting.Invoices.stream(tokens, tenant_id,
  if_modified_since: last_sync)
|> Enum.each(&upsert_invoice/1)
```

---

## Telemetry

```elixir
# Attach in Application.start/2
:telemetry.attach_many("my-app-xero", [
  [:xero, :http, :request],
  [:xero, :rate_limit, :remaining],
  [:xero, :auth, :token_refreshed],
  [:xero, :auth, :token_refresh_failed]
], &MyApp.XeroTelemetry.handle_event/4, nil)

# telemetry_metrics definitions
[
  Telemetry.Metrics.summary("xero.http.request.duration",
    unit: {:native, :millisecond},
    tags: [:method, :status, :tenant_id]),
  Telemetry.Metrics.last_value("xero.rate_limit.remaining.day_remaining"),
  Telemetry.Metrics.last_value("xero.rate_limit.remaining.min_remaining"),
  Telemetry.Metrics.counter("xero.auth.token_refreshed"),
  Telemetry.Metrics.counter("xero.auth.token_refresh_failed")
]
```

---

## Rate Limits

Xero enforces three tiers — the client tracks all three:

| Limit               | Value  | Tracking                            |
| ------------------- | ------ | ----------------------------------- |
| Per tenant / minute | 60     | ETS token bucket                    |
| Per tenant / day    | 5 000  | ETS counter                         |
| App-wide / minute   | 10 000 | `X-AppMinLimit-Remaining` telemetry |

`Retry-After` headers on 429 responses are respected automatically.

---

## Development

```bash
mix deps.get
mix test
mix test --cover
mix credo --strict
mix dialyzer
mix docs
```

---

## License

MIT © 2024 iamkanishka
