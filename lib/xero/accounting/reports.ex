defmodule Xero.Accounting.Reports do
  @moduledoc """
  Xero Accounting API – Financial Reports.

  Requires `accounting.reports.read` scope.
  Standard users with the "No reports" role receive HTTP 403.
  Organisations using cashflow basis: use `payments_only: true`.

  ## Available Reports

  | Function | Xero Report | Notes |
  |----------|------------|-------|
  | `balance_sheet/3` | Balance Sheet | Assets, liabilities, equity |
  | `profit_and_loss/3` | Profit and Loss | Revenue and expenses |
  | `trial_balance/3` | Trial Balance | All accounts with debit/credit balances |
  | `executive_summary/3` | Executive Summary | KPI dashboard |
  | `bank_summary/3` | Bank Summary | Bank account movements |
  | `budget_summary/3` | Budget Summary | Budget vs actuals |
  | `aged_receivables/4` | Aged Receivables By Contact | Debtors report |
  | `aged_payables/4` | Aged Payables By Contact | Creditors report |
  | `ten_ninety_nine/3` | 1099 Report | US only |
  | `bas/2` | BAS Report | AU only |
  | `gst/3` | GST Report | AU/NZ only |
  | `list/2` | Report Index | All available reports |
  """

  use Xero.API.Base, api: :accounting

  @doc """
  Returns the Balance Sheet report.

  ## Options

  - `:date` — Reporting date (YYYY-MM-DD, default: today)
  - `:periods` — Number of comparison periods (0–11)
  - `:time_frame` — `"MONTH"` | `"QUARTER"` | `"YEAR"`
  - `:tracking_option_id1` / `:tracking_option_id2` — Filter by tracking options
  - `:standard_layout` — Use standard layout (boolean, default true)
  - `:payments_only` — Cash-basis mode (boolean, default false)
  """
  @spec balance_sheet(Token.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def balance_sheet(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Reports/BalanceSheet", %{
        "date" => opts[:date],
        "periods" => opts[:periods],
        "timeframe" => opts[:time_frame],
        "trackingOptionID1" => opts[:tracking_option_id1],
        "trackingOptionID2" => opts[:tracking_option_id2],
        "standardLayout" => opts[:standard_layout],
        "paymentsOnly" => opts[:payments_only]
      })
    )
  end

  @doc """
  Returns the Profit and Loss report.

  ## Options

  - `:from_date` / `:to_date` — Date range (YYYY-MM-DD)
  - `:periods` — Number of comparison periods (0–11)
  - `:time_frame` — `"MONTH"` | `"QUARTER"` | `"YEAR"`
  - `:tracking_category_id` / `:tracking_category_id2` — Segment by tracking category
  - `:tracking_option_id` / `:tracking_option_id2` — Filter by specific tracking option
  - `:standard_layout` — Use standard layout (boolean)
  - `:payments_only` — Cash-basis mode (boolean)
  """
  @spec profit_and_loss(Token.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def profit_and_loss(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Reports/ProfitAndLoss", %{
        "fromDate" => opts[:from_date],
        "toDate" => opts[:to_date],
        "periods" => opts[:periods],
        "timeframe" => opts[:time_frame],
        "trackingCategoryID" => opts[:tracking_category_id],
        "trackingCategoryID2" => opts[:tracking_category_id2],
        "trackingOptionID" => opts[:tracking_option_id],
        "trackingOptionID2" => opts[:tracking_option_id2],
        "standardLayout" => opts[:standard_layout],
        "paymentsOnly" => opts[:payments_only]
      })
    )
  end

  @doc """
  Returns the Trial Balance report.

  ## Options

  - `:date` — Reporting date (YYYY-MM-DD)
  - `:payments_only` — Cash-basis mode (boolean)
  """
  @spec trial_balance(Token.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def trial_balance(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Reports/TrialBalance", %{
        "date" => opts[:date],
        "paymentsOnly" => opts[:payments_only]
      })
    )
  end

  @doc """
  Returns the Executive Summary report (KPI dashboard).

  ## Options

  - `:date` — Reporting date (YYYY-MM-DD)
  """
  @spec executive_summary(Token.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def executive_summary(%Token{} = t, tid, opts \\ []) do
    ok_body(req_get(t, tid, "/Reports/ExecutiveSummary", %{"date" => opts[:date]}))
  end

  @doc """
  Returns the Bank Summary report.

  ## Options

  - `:from_date` / `:to_date` — Date range (YYYY-MM-DD)
  """
  @spec bank_summary(Token.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def bank_summary(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Reports/BankSummary", %{
        "fromDate" => opts[:from_date],
        "toDate" => opts[:to_date]
      })
    )
  end

  @doc """
  Returns the Budget Summary report.

  ## Options

  - `:date` — Reporting date (YYYY-MM-DD)
  - `:periods` — Number of periods (1–12)
  - `:time_frame` — `"MONTH"` | `"QUARTER"` | `"YEAR"`
  """
  @spec budget_summary(Token.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def budget_summary(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Reports/BudgetSummary", %{
        "date" => opts[:date],
        "periods" => opts[:periods],
        "timeframe" => opts[:time_frame]
      })
    )
  end

  @doc """
  Returns the Aged Receivables By Contact report for a specific contact.

  ## Parameters

  - `contact_id` — UUID of the contact (required)

  ## Options

  - `:date` — Reporting date (YYYY-MM-DD)
  - `:from_date` / `:to_date` — Date range
  """
  @spec aged_receivables(Token.t(), String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def aged_receivables(%Token{} = t, tid, contact_id, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Reports/AgedReceivablesByContact", %{
        "contactID" => contact_id,
        "date" => opts[:date],
        "fromDate" => opts[:from_date],
        "toDate" => opts[:to_date]
      })
    )
  end

  @doc """
  Returns the Aged Payables By Contact report for a specific contact.

  ## Parameters

  - `contact_id` — UUID of the contact (required)

  ## Options

  - `:date` — Reporting date (YYYY-MM-DD)
  - `:from_date` / `:to_date` — Date range
  """
  @spec aged_payables(Token.t(), String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def aged_payables(%Token{} = t, tid, contact_id, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Reports/AgedPayablesByContact", %{
        "contactID" => contact_id,
        "date" => opts[:date],
        "fromDate" => opts[:from_date],
        "toDate" => opts[:to_date]
      })
    )
  end

  @doc """
  Returns the 1099 report (US organisations only).

  ## Options

  - `:report_year` — Tax year (e.g. `"2024"`)
  """
  @spec ten_ninety_nine(Token.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def ten_ninety_nine(%Token{} = t, tid, opts \\ []) do
    ok_body(req_get(t, tid, "/Reports/TenNinetyNine", %{"reportYear" => opts[:report_year]}))
  end

  @doc """
  Returns the BAS (Business Activity Statement) report for AU organisations.
  Returns a list of all completed BAS reports with no parameters.
  """
  @spec bas(Token.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def bas(%Token{} = t, tid), do: ok_body(req_get(t, tid, "/Reports/BAS"))

  @doc """
  Returns a specific BAS report by ID (AU organisations only).
  """
  @spec get_bas(Token.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get_bas(%Token{} = t, tid, bas_id), do: ok_body(req_get(t, tid, "/Reports/BAS/#{bas_id}"))

  @doc """
  Returns the GST report (AU/NZ organisations only).

  ## Options

  - `:from_date` / `:to_date` — Reporting period (YYYY-MM-DD)
  """
  @spec gst(Token.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def gst(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Reports/GST", %{
        "fromDate" => opts[:from_date],
        "toDate" => opts[:to_date]
      })
    )
  end

  @doc """
  Returns a specific GST report by ID (AU/NZ only).
  """
  @spec get_gst(Token.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get_gst(%Token{} = t, tid, report_id),
    do: ok_body(req_get(t, tid, "/Reports/GST/#{report_id}"))

  @doc "Lists all reports available to the connected organisation."
  @spec list(Token.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def list(%Token{} = t, tid), do: ok_body(req_get(t, tid, "/Reports"))
end
