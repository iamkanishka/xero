defmodule Xero.Finance do
  @moduledoc """
  Xero Finance API – Financial data endpoints for lending and accounting activity analysis.
  Base URL: `https://api.xero.com/finance.xro/1.0/`

  ## Scopes Required

  | Endpoint | Scope |
  |----------|-------|
  | Bank Statements Plus | `finance.statements.read` |
  | Cash Validation | `finance.cashvalidation.read` |
  | Financial Statements | `finance.financialstatements.read` |
  | Accounting Activity | `finance.accountingactivity.read` |

  ## Sub-APIs

  - **Bank Statements Plus** — Raw bank statement lines with merchant enrichment and categorisation
  - **Cash Validation** — Validates cash position accuracy between bank statements and Xero
  - **Financial Statements** — Balance Sheet, P&L, Trial Balance, Cash Flow (snapshot views)
  - **Accounting Activity** — Lock history, report activity, and user activity statistics

  ## Examples

      # Check if cash balances match bank statements
      {:ok, validation} = Xero.Finance.cash_validation(token, tenant_id,
        balance_date: "2024-01-31")

      # Get enriched bank statement data for lending
      {:ok, data} = Xero.Finance.bank_statements(token, tenant_id,
        bank_account_id: "account-uuid",
        from_date: "2024-01-01",
        to_date: "2024-12-31")
  """

  use Xero.API.Base, api: :finance

  # ─── Bank Statements Plus ─────────────────────────────────────────────────────

  @doc """
  Returns enriched bank statement data with merchant categorisation.
  Scope: `finance.statements.read`

  ## Options

  - `:bank_account_id` — UUID of the bank account (required)
  - `:from_date` — Start date (YYYY-MM-DD)
  - `:to_date` — End date (YYYY-MM-DD)
  - `:summary_only` — Return aggregated summary only (boolean)
  """
  @spec bank_statements(Token.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def bank_statements(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/BankStatementsPlus/statements", %{
        "bankAccountID" => opts[:bank_account_id],
        "fromDate" => opts[:from_date],
        "toDate" => opts[:to_date],
        "summaryOnly" => opts[:summary_only]
      })
    )
  end

  # ─── Cash Validation ─────────────────────────────────────────────────────────

  @doc """
  Validates cash position accuracy — identifies discrepancies between Xero account
  balances and the actual bank statement balances.
  Scope: `finance.cashvalidation.read`

  ## Options

  - `:balance_date` — Date to validate cash position (YYYY-MM-DD)
  - `:begin_date` — Start of validation period
  - `:include_credit_transactions` — Include credit card accounts (boolean, default false)
  """
  @spec cash_validation(Token.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def cash_validation(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/CashValidation", %{
        "balanceDate" => opts[:balance_date],
        "beginDate" => opts[:begin_date],
        "includeCreditTransactions" => opts[:include_credit_transactions]
      })
    )
  end

  # ─── Financial Statements ─────────────────────────────────────────────────────

  @doc """
  Returns a Balance Sheet snapshot.
  Scope: `finance.financialstatements.read`

  ## Options

  - `:balance_date` — Reporting date (YYYY-MM-DD)
  - `:periods` — Number of comparison periods
  - `:timeframe` — `"MONTH"` | `"QUARTER"` | `"YEAR"`
  - `:tracking_category_id` / `:tracking_option_id` — Filter by tracking segment
  - `:standard_layout` — Use standard layout (boolean)
  - `:payments_only` — Cash-basis reporting (boolean)
  """
  @spec balance_sheet(Token.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def balance_sheet(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/FinancialStatements/balanceSheet", %{
        "balanceDate" => opts[:balance_date],
        "periods" => opts[:periods],
        "timeframe" => opts[:timeframe],
        "trackingCategoryID" => opts[:tracking_category_id],
        "trackingOptionID" => opts[:tracking_option_id],
        "standardLayout" => opts[:standard_layout],
        "paymentsOnly" => opts[:payments_only]
      })
    )
  end

  @doc """
  Returns a Profit and Loss statement.
  Scope: `finance.financialstatements.read`

  ## Options

  - `:start_month` — Start month (YYYY-MM)
  - `:end_month` — End month (YYYY-MM)
  - `:periods` — Number of comparison periods
  - `:timeframe` — `"MONTH"` | `"QUARTER"` | `"YEAR"`
  - `:tracking_category_id` / `:tracking_category_id2` — Filter by tracking segment
  - `:standard_layout` — Use standard layout (boolean)
  - `:payments_only` — Cash-basis reporting (boolean)
  """
  @spec profit_and_loss(Token.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def profit_and_loss(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/FinancialStatements/profitAndLoss", %{
        "startMonth" => opts[:start_month],
        "endMonth" => opts[:end_month],
        "periods" => opts[:periods],
        "timeframe" => opts[:timeframe],
        "trackingCategoryID" => opts[:tracking_category_id],
        "trackingCategoryID2" => opts[:tracking_category_id2],
        "standardLayout" => opts[:standard_layout],
        "paymentsOnly" => opts[:payments_only]
      })
    )
  end

  @doc """
  Returns a Trial Balance snapshot.
  Scope: `finance.financialstatements.read`

  ## Options

  - `:end_month` — Reporting month (YYYY-MM)
  - `:start_month` — Start of range for comparison
  """
  @spec trial_balance(Token.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def trial_balance(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/FinancialStatements/trialBalance", %{
        "endMonth" => opts[:end_month],
        "startMonth" => opts[:start_month]
      })
    )
  end

  @doc """
  Returns a Cash Flow Statement.
  Scope: `finance.financialstatements.read`

  ## Options

  - `:start_month` — Start month (YYYY-MM)
  - `:end_month` — End month (YYYY-MM)
  """
  @spec cash_flow(Token.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def cash_flow(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/FinancialStatements/cashflow", %{
        "startMonth" => opts[:start_month],
        "endMonth" => opts[:end_month]
      })
    )
  end

  # ─── Accounting Activity ──────────────────────────────────────────────────────

  @doc """
  Returns ledger lock history (period-end lock dates).
  Scope: `finance.accountingactivity.read`

  ## Options

  - `:start_month` — Start month (YYYY-MM)
  - `:end_month` — End month (YYYY-MM)
  """
  @spec accounting_activity(Token.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def accounting_activity(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/AccountingActivities/lockHistory", %{
        "startMonth" => opts[:start_month],
        "endMonth" => opts[:end_month]
      })
    )
  end

  @doc """
  Returns report activity statistics (number of reports run, users, frequency).
  Scope: `finance.accountingactivity.read`

  ## Options

  - `:start_month` — Start month (YYYY-MM)
  - `:end_month` — End month (YYYY-MM)
  """
  @spec report_activity(Token.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def report_activity(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/AccountingActivities/reportActivity", %{
        "startMonth" => opts[:start_month],
        "endMonth" => opts[:end_month]
      })
    )
  end

  @doc """
  Returns user activity statistics (active users, activity levels).
  Scope: `finance.accountingactivity.read`

  ## Options

  - `:data_month` — Month to query (YYYY-MM)
  """
  @spec user_activities(Token.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def user_activities(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/AccountingActivities/userActivities", %{
        "dataMonth" => opts[:data_month]
      })
    )
  end

  @doc """
  Returns an overview of the organisation's accounting activity.
  Scope: `finance.accountingactivity.read`

  ## Options

  - `:start_month` — Start month (YYYY-MM)
  - `:end_month` — End month (YYYY-MM)
  """
  @spec accounting_activity_overview(Token.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def accounting_activity_overview(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/AccountingActivities", %{
        "startMonth" => opts[:start_month],
        "endMonth" => opts[:end_month]
      })
    )
  end
end
