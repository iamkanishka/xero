defmodule Xero.Payroll.AU do
  @moduledoc """
  Xero Payroll API – Australia.
  Base URL: `https://api.xero.com/payroll.xro/1.0/`
  Scopes: `payroll.employees`, `payroll.payruns`, `payroll.payslip`, `payroll.settings`
  """
  use Xero.API.Base, api: :payroll_au

  # ─── Employees ──────────────────────────────────────────────────────────────

  def list_employees(%Token{} = t, tid, opts \\ []) do
    params = %{"page" => opts[:page], "where" => opts[:where], "order" => opts[:order]}

    case opts[:if_modified_since] do
      nil -> ok_body(req_get(t, tid, "/Employees", params))
      since -> ok_body(req_get_modified(t, tid, "/Employees", since, params))
    end
  end

  def get_employee(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Employees/#{id}"))

  def create_employee(%Token{} = t, tid, attrs),
    do: ok_body(post(t, tid, "/Employees", %{"Employees" => [attrs]}))

  def update_employee(%Token{} = t, tid, id, attrs) do
    ok_body(post(t, tid, "/Employees/#{id}", %{"Employees" => [attrs]}))
  end

  @doc "Returns leave balances for an employee."
  def get_employee_leave_balances(%Token{} = t, tid, employee_id) do
    ok_body(req_get(t, tid, "/Employees/#{employee_id}/LeaveBalances"))
  end

  @doc "Returns the leave period for an employee in a specific year."
  def get_employee_leave_periods(%Token{} = t, tid, employee_id, opts \\ []) do
    params = %{"StartDate" => opts[:start_date], "EndDate" => opts[:end_date]}
    ok_body(req_get(t, tid, "/Employees/#{employee_id}/LeavePeriods", params))
  end

  @doc "Returns leave summary for an employee."
  def get_employee_leave_summary(%Token{} = t, tid, employee_id) do
    ok_body(req_get(t, tid, "/Employees/#{employee_id}/LeaveSummary"))
  end

  @doc "Updates bank account details for an employee."
  def update_employee_bank_account(%Token{} = t, tid, employee_id, attrs) do
    ok_body(post(t, tid, "/Employees/#{employee_id}/BankAccounts", attrs))
  end

  @doc "Updates tax declaration for an employee."
  def update_employee_tax(%Token{} = t, tid, employee_id, attrs) do
    ok_body(
      post(t, tid, "/Employees/#{employee_id}/TaxDeclaration", %{"TaxDeclaration" => attrs})
    )
  end

  @doc "Updates opening balances for an employee."
  def update_employee_opening_balances(%Token{} = t, tid, employee_id, attrs) do
    ok_body(post(t, tid, "/Employees/#{employee_id}/OpeningBalances", attrs))
  end

  # ─── Pay Items ──────────────────────────────────────────────────────────────

  def list_pay_items(%Token{} = t, tid, opts \\ []) do
    ok_body(req_get(t, tid, "/PayItems", %{"where" => opts[:where], "order" => opts[:order]}))
  end

  def create_pay_item(%Token{} = t, tid, attrs), do: ok_body(post(t, tid, "/PayItems", attrs))
  def update_pay_item(%Token{} = t, tid, attrs), do: ok_body(post(t, tid, "/PayItems", attrs))

  @doc "Deletes a pay item by ID."
  def delete_pay_item(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/PayItems/#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ─── Payroll Calendars ──────────────────────────────────────────────────────

  def list_payroll_calendars(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/PayrollCalendars", %{"where" => opts[:where], "order" => opts[:order]})
    )
  end

  def get_payroll_calendar(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/PayrollCalendars/#{id}"))

  def create_payroll_calendar(%Token{} = t, tid, attrs) do
    ok_body(post(t, tid, "/PayrollCalendars", %{"PayrollCalendars" => [attrs]}))
  end

  def update_payroll_calendar(%Token{} = t, tid, id, attrs) do
    ok_body(post(t, tid, "/PayrollCalendars/#{id}", %{"PayrollCalendars" => [attrs]}))
  end

  # ─── Pay Runs ────────────────────────────────────────────────────────────────

  def list_pay_runs(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/PayRuns", %{
        "page" => opts[:page],
        "where" => opts[:where],
        "order" => opts[:order]
      })
    )
  end

  def get_pay_run(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/PayRuns/#{id}"))

  def create_pay_run(%Token{} = t, tid, attrs),
    do: ok_body(post(t, tid, "/PayRuns", %{"PayRuns" => [attrs]}))

  def update_pay_run(%Token{} = t, tid, id, attrs),
    do: ok_body(post(t, tid, "/PayRuns/#{id}", %{"PayRuns" => [attrs]}))

  @doc "Posts (finalises) a pay run."
  def post_pay_run(%Token{} = t, tid, id) do
    ok_body(
      post(t, tid, "/PayRuns/#{id}", %{
        "PayRuns" => [%{"PayRunID" => id, "PayRunStatus" => "POSTED"}]
      })
    )
  end

  @doc "Deletes a DRAFT pay run."
  def delete_pay_run(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/PayRuns/#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ─── Payslips ────────────────────────────────────────────────────────────────

  def get_payslip(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Payslip/#{id}"))

  def update_payslip(%Token{} = t, tid, id, attrs),
    do: ok_body(post(t, tid, "/Payslip/#{id}", %{"Payslip" => attrs}))

  # ─── Timesheets ──────────────────────────────────────────────────────────────

  def list_timesheets(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Timesheets", %{
        "page" => opts[:page],
        "where" => opts[:where],
        "order" => opts[:order]
      })
    )
  end

  def get_timesheet(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Timesheets/#{id}"))

  def create_timesheet(%Token{} = t, tid, attrs),
    do: ok_body(post(t, tid, "/Timesheets", %{"Timesheets" => [attrs]}))

  def update_timesheet(%Token{} = t, tid, id, attrs) do
    ok_body(post(t, tid, "/Timesheets/#{id}", %{"Timesheets" => [attrs]}))
  end

  def approve_timesheet(%Token{} = t, tid, id),
    do: ok_body(post(t, tid, "/Timesheets/#{id}/Approve", %{}))

  def revert_timesheet(%Token{} = t, tid, id),
    do: ok_body(post(t, tid, "/Timesheets/#{id}/Revert", %{}))

  @doc "Deletes a DRAFT timesheet."
  def delete_timesheet(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/Timesheets/#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ─── Leave Types ─────────────────────────────────────────────────────────────

  @doc "Lists leave types for the organisation."
  def list_leave_types(%Token{} = t, tid, opts \\ []) do
    ok_body(req_get(t, tid, "/PayItems", %{"where" => opts[:where]}))
  end

  # ─── Leave Applications ──────────────────────────────────────────────────────

  def list_leave_applications(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/LeaveApplications", %{
        "page" => opts[:page],
        "where" => opts[:where],
        "order" => opts[:order]
      })
    )
  end

  def get_leave_application(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/LeaveApplications/#{id}"))

  def create_leave_application(%Token{} = t, tid, attrs) do
    ok_body(post(t, tid, "/LeaveApplications", %{"LeaveApplications" => [attrs]}))
  end

  def update_leave_application(%Token{} = t, tid, id, attrs) do
    ok_body(post(t, tid, "/LeaveApplications/#{id}", %{"LeaveApplications" => [attrs]}))
  end

  @doc "Deletes a leave application."
  def delete_leave_application(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/LeaveApplications/#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ─── Settings & Superfunds ───────────────────────────────────────────────────

  def settings(%Token{} = t, tid), do: ok_body(req_get(t, tid, "/Settings"))

  def superfunds(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Superfunds", %{
        "page" => opts[:page],
        "where" => opts[:where],
        "order" => opts[:order]
      })
    )
  end

  def get_superfund(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Superfunds/#{id}"))

  @doc "Returns superfund products available in Australia."
  def superfund_products(%Token{} = t, tid, opts \\ []) do
    ok_body(req_get(t, tid, "/SuperfundProducts", %{"ABN" => opts[:abn], "USI" => opts[:usi]}))
  end
end
