defmodule Xero.BankFeeds do
  @moduledoc """
  Xero Bank Feeds API – Push bank statement data into Xero for auto-reconciliation.
  Base URL: `https://api.xero.com/bankfeeds.xro/1.0/`
  Scope: `bankfeeds`

  ⚠️  Requires Xero Bank Feeds partner programme approval before use.
  Contact Xero to apply: https://developer.xero.com/documentation/bank-feeds-api/overview/

  ## Workflow

  1. Create a feed connection for each bank account
  2. Push statement lines to the connection periodically
  3. Xero auto-matches and reconciles transactions

  ## Statement Line Fields

  | Field | Required | Description |
  |-------|----------|-------------|
  | `postedDate` | ✅ | Transaction date (YYYY-MM-DD) |
  | `description` | ✅ | Transaction description |
  | `amount` | ✅ | Decimal amount (always positive) |
  | `creditDebitIndicator` | ✅ | `"CREDIT"` or `"DEBIT"` |
  | `transactionId` | — | Your unique ID (strongly recommended for idempotency) |
  | `payeeName` | — | Merchant or payee name |
  | `reference` | — | Your reference |
  | `chequeNumber` | — | Cheque number |
  | `subType` | — | Transaction sub-type (for categorisation) |

  ## Examples

      {:ok, conn} = Xero.BankFeeds.create_feed_connection(token, tenant_id, %{
        "accountToken"  => "my-unique-token",
        "accountType"   => "BANK",
        "accountName"   => "Business Cheque",
        "accountNumber" => "123456789",
        "currency"      => "AUD"
      })

      {:ok, _} = Xero.BankFeeds.create_statements(token, tenant_id, %{
        "feedConnectionId" => conn_id,
        "startDate"        => "2024-01-01",
        "endDate"          => "2024-01-31",
        "startBalance"     => %{"amount" => "1000.00", "creditDebitIndicator" => "CREDIT"},
        "endBalance"       => %{"amount" => "1500.00", "creditDebitIndicator" => "CREDIT"},
        "statementLines"   => [
          %{
            "postedDate"           => "2024-01-15",
            "description"          => "Client Payment",
            "amount"               => "5000.00",
            "creditDebitIndicator" => "CREDIT",
            "transactionId"        => "TXN-2024-001"
          }
        ]
      })
  """

  use Xero.API.Base, api: :bankfeeds

  # ─── Feed Connections ─────────────────────────────────────────────────────────

  @doc """
  Lists all feed connections. Options: `:page`, `:page_size`
  """
  @spec list_feed_connections(Token.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def list_feed_connections(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/FeedConnections", %{
        "page" => opts[:page],
        "pageSize" => opts[:page_size]
      })
    )
  end

  @doc "Retrieves a single feed connection by ID."
  @spec get_feed_connection(Token.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Error.t()}
  def get_feed_connection(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/FeedConnections/#{id}"))

  @doc """
  Creates one or more feed connections (pass a single map or a list).

  ## Required fields per connection

  - `"accountToken"` — Your unique identifier for this bank account (max 50 chars)
  - `"accountType"` — `"BANK"` or `"CREDITCARD"`
  - `"accountName"` — Display name in Xero (max 30 chars)
  - `"accountNumber"` — Bank account number (max 12 chars)
  - `"currency"` — ISO 4217 currency code (e.g. `"AUD"`, `"GBP"`)

  ## Region-specific required fields

  - UK: `"sortCode"` (format `"12-34-56"`)
  - AU: `"bsb"` (format `"123456"`)
  """
  @spec create_feed_connection(Token.t(), String.t(), map() | list(map())) ::
          {:ok, map()} | {:error, Error.t()}
  def create_feed_connection(%Token{} = t, tid, conn_or_conns) do
    ok_body(post(t, tid, "/FeedConnections", %{"items" => List.wrap(conn_or_conns)}))
  end

  @doc """
  Deletes feed connections by their IDs.
  Uses the `DeleteRequests` endpoint (POST, not DELETE).
  """
  @spec delete_feed_connections(Token.t(), String.t(), list(String.t())) ::
          {:ok, map()} | {:error, Error.t()}
  def delete_feed_connections(%Token{} = t, tid, ids) do
    body = %{"items" => Enum.map(ids, &%{"id" => &1})}
    ok_body(Client.post(url("/FeedConnections/DeleteRequests"), body, t, [], tenant_id: tid))
  end

  # ─── Statements ──────────────────────────────────────────────────────────────

  @doc """
  Lists statements. Options: `:feed_connection_id`, `:page`, `:page_size`
  """
  @spec list_statements(Token.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def list_statements(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Statements", %{
        "feedConnectionId" => opts[:feed_connection_id],
        "page" => opts[:page],
        "pageSize" => opts[:page_size]
      })
    )
  end

  @doc "Retrieves a single statement by ID."
  @spec get_statement(Token.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get_statement(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Statements/#{id}"))

  @doc """
  Pushes one or more bank statements into Xero (pass a single map or a list).

  Each statement represents one bank account period and must include:
  - `"feedConnectionId"` — UUID of the feed connection
  - `"startDate"` / `"endDate"` — Statement period (YYYY-MM-DD)
  - `"startBalance"` / `"endBalance"` — Balance maps with `amount` and `creditDebitIndicator`
  - `"statementLines"` — List of transaction maps

  Use `transactionId` in each statement line for idempotency — Xero will reject
  duplicate `transactionId` values for the same feed connection.
  """
  @spec create_statements(Token.t(), String.t(), map() | list(map())) ::
          {:ok, map()} | {:error, Error.t()}
  def create_statements(%Token{} = t, tid, stmt_or_stmts) do
    ok_body(post(t, tid, "/Statements", %{"items" => List.wrap(stmt_or_stmts)}))
  end

  @doc """
  Deletes a statement by ID.
  Note: Only statements that have not yet been reconciled can be deleted.
  """
  @spec delete_statement(Token.t(), String.t(), String.t()) :: :ok | {:error, Error.t()}
  def delete_statement(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/Statements/#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
