defmodule Xero do
  @moduledoc """
  A complete, production-grade Elixir client for all 13 Xero APIs.

  ## Supported APIs

  | Module | API |
  |--------|-----|
  | `Xero.Accounting.*` | Accounting API (invoices, contacts, payments, reports, …) |
  | `Xero.Assets` | Fixed asset management |
  | `Xero.BankFeeds` | Push bank statement data |
  | `Xero.Files` | Document and attachment management |
  | `Xero.Finance` | Financial statements for lending |
  | `Xero.Projects` | Project time and cost tracking |
  | `Xero.Payroll.AU` | Australian payroll |
  | `Xero.Payroll.NZ` | New Zealand payroll |
  | `Xero.Payroll.UK` | UK payroll and HMRC |
  | `Xero.PracticeManager` | Accounting practice management |
  | `Xero.AppStore` | Subscription and billing management |
  | `Xero.EInvoicing` | PEPPOL-compliant e-invoicing |

  ## Quick Start

      # 1. Configure
      config :xero,
        client_id: System.fetch_env!("XERO_CLIENT_ID"),
        client_secret: System.fetch_env!("XERO_CLIENT_SECRET"),
        redirect_uri: "https://yourapp.com/oauth/callback",
        scopes: ~w(openid profile email offline_access accounting.transactions accounting.contacts)

      # 2. Generate the auth URL
      {:ok, url, state} = Xero.Auth.authorize_url()

      # 3. Exchange the callback code for tokens
      {:ok, tokens} = Xero.Auth.fetch_token(code)

      # 4. List connected tenants
      {:ok, [tenant | _]} = Xero.Auth.connections(tokens)

      # 5. Make API calls
      {:ok, result} = Xero.Accounting.Invoices.list(tokens, tenant.tenant_id, page: 1)
  """

  @version Mix.Project.config()[:version]

  @doc "Returns the library version."
  @spec version() :: String.t()
  def version, do: @version
end
