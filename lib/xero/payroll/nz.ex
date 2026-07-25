defmodule Xero.Payroll.NZ do
  @moduledoc """
  Xero Payroll API – New Zealand.
  Base URL: `https://api.xero.com/payrollnz.xro/1.0/`
  Scopes: `payroll.employees`, `payroll.payruns`, `payroll.payslip`, `payroll.settings`
  Covers NZ payroll including PAYE, KiwiSaver, and NZ leave entitlements.
  """
  use Xero.API.Base, api: :payroll_nz

  # ─── Employees ──────────────────────────────────────────────────────────────

  def list_employees(%Token{} = t, tid, opts \\ []) do
    ok_body(req_get(t, tid, "/Employees", %{"page" => opts[:page], "filter" => opts[:filter]}))
  end

  def get_employee(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Employees/#{id}"))
  def create_employee(%Token{} = t, tid, attrs), do: ok_body(post(t, tid, "/Employees", attrs))

  def update_employee(%Token{} = t, tid, id, attrs),
    do: ok_body(put(t, tid, "/Employees/#{id}", attrs))

  @doc "Returns tax settings for a NZ employee."
  def get_employee_tax(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/Employees/#{id}/Tax"))

  def update_employee_tax(%Token{} = t, tid, id, attrs),
    do: ok_body(post(t, tid, "/Employees/#{id}/Tax", attrs))

  @doc "Returns leave balances for an employee."
  def get_employee_leave_balances(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/Employees/#{id}/LeaveBalances"))

  @doc "Returns leave for an employee."
  def get_employee_leave(%Token{} = t, tid, id, opts \\ []) do
    ok_body(req_get(t, tid, "/Employees/#{id}/Leave", %{"page" => opts[:page]}))
  end

  @doc "Creates leave for an employee."
  def create_employee_leave(%Token{} = t, tid, id, attrs),
    do: ok_body(post(t, tid, "/Employees/#{id}/Leave", attrs))

  @doc "Updates leave for an employee."
  def update_employee_leave(%Token{} = t, tid, id, leave_id, attrs),
    do: ok_body(put(t, tid, "/Employees/#{id}/Leave/#{leave_id}", attrs))

  @doc "Deletes leave for an employee."
  def delete_employee_leave(%Token{} = t, tid, id, leave_id) do
    case req_delete(t, tid, "/Employees/#{id}/Leave/#{leave_id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ─── Pay Runs ────────────────────────────────────────────────────────────────

  def list_pay_runs(%Token{} = t, tid, opts \\ []) do
    ok_body(req_get(t, tid, "/PayRuns", %{"page" => opts[:page], "status" => opts[:status]}))
  end

  def get_pay_run(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/PayRuns/#{id}"))

  @doc "Creates a new pay run from a pay run calendar."
  def create_pay_run(%Token{} = t, tid, attrs), do: ok_body(post(t, tid, "/PayRuns", attrs))

  @doc "Updates a pay run (e.g. to set payment date)."
  def update_pay_run(%Token{} = t, tid, id, attrs),
    do: ok_body(put(t, tid, "/PayRuns/#{id}", attrs))

  @doc "Posts (finalises) a pay run."
  def post_pay_run(%Token{} = t, tid, id),
    do: ok_body(post(t, tid, "/PayRuns/#{id}/Post", %{}))

  @doc "Reverts a posted pay run back to DRAFT."
  def revert_pay_run(%Token{} = t, tid, id),
    do: ok_body(post(t, tid, "/PayRuns/#{id}/Revert", %{}))

  @doc "Deletes a DRAFT pay run."
  def delete_pay_run(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/PayRuns/#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ─── Pay Run Calendars ───────────────────────────────────────────────────────

  def list_pay_run_calendar(%Token{} = t, tid, opts \\ []) do
    ok_body(req_get(t, tid, "/PayRunCalendars", %{"page" => opts[:page]}))
  end

  def get_pay_run_calendar(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/PayRunCalendars/#{id}"))

  def create_pay_run_calendar(%Token{} = t, tid, attrs),
    do: ok_body(post(t, tid, "/PayRunCalendars", attrs))

  # ─── Payslips ────────────────────────────────────────────────────────────────

  def get_payslip(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Payslips/#{id}"))

  def update_payslip(%Token{} = t, tid, id, attrs),
    do: ok_body(put(t, tid, "/Payslips/#{id}", attrs))

  # ─── Earnings Rates & Deductions ─────────────────────────────────────────────

  def list_earnings_rates(%Token{} = t, tid, opts \\ []) do
    ok_body(req_get(t, tid, "/EarningsRates", %{"page" => opts[:page]}))
  end

  def get_earnings_rate(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/EarningsRates/#{id}"))

  def create_earnings_rate(%Token{} = t, tid, attrs),
    do: ok_body(post(t, tid, "/EarningsRates", attrs))

  def update_earnings_rate(%Token{} = t, tid, id, attrs),
    do: ok_body(put(t, tid, "/EarningsRates/#{id}", attrs))

  def list_deduction_types(%Token{} = t, tid, opts \\ []) do
    ok_body(req_get(t, tid, "/DeductionTypes", %{"page" => opts[:page]}))
  end

  def get_deduction_type(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/DeductionTypes/#{id}"))

  def create_deduction_type(%Token{} = t, tid, attrs),
    do: ok_body(post(t, tid, "/DeductionTypes", attrs))

  def update_deduction_type(%Token{} = t, tid, id, attrs),
    do: ok_body(put(t, tid, "/DeductionTypes/#{id}", attrs))

  # ─── Leave Types ─────────────────────────────────────────────────────────────

  def list_leave_types(%Token{} = t, tid, opts \\ []) do
    ok_body(req_get(t, tid, "/LeaveTypes", %{"page" => opts[:page]}))
  end

  def get_leave_type(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/LeaveTypes/#{id}"))
  def create_leave_type(%Token{} = t, tid, attrs), do: ok_body(post(t, tid, "/LeaveTypes", attrs))

  def update_leave_type(%Token{} = t, tid, id, attrs),
    do: ok_body(put(t, tid, "/LeaveTypes/#{id}", attrs))

  # ─── Reimbursements ──────────────────────────────────────────────────────────

  def list_reimbursements(%Token{} = t, tid, opts \\ []) do
    ok_body(req_get(t, tid, "/Reimbursements", %{"page" => opts[:page]}))
  end

  def get_reimbursement(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/Reimbursements/#{id}"))

  def create_reimbursement(%Token{} = t, tid, attrs),
    do: ok_body(post(t, tid, "/Reimbursements", attrs))

  def update_reimbursement(%Token{} = t, tid, id, attrs),
    do: ok_body(put(t, tid, "/Reimbursements/#{id}", attrs))

  # ─── Timesheets ──────────────────────────────────────────────────────────────

  def list_timesheets(%Token{} = t, tid, opts \\ []) do
    ok_body(req_get(t, tid, "/Timesheets", %{"page" => opts[:page], "status" => opts[:status]}))
  end

  def get_timesheet(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Timesheets/#{id}"))
  def create_timesheet(%Token{} = t, tid, attrs), do: ok_body(post(t, tid, "/Timesheets", attrs))

  def approve_timesheet(%Token{} = t, tid, id),
    do: ok_body(post(t, tid, "/Timesheets/#{id}/Approve", %{}))

  def revert_timesheet(%Token{} = t, tid, id),
    do: ok_body(post(t, tid, "/Timesheets/#{id}/Revert", %{}))

  # ─── Settings ────────────────────────────────────────────────────────────────

  def settings(%Token{} = t, tid), do: ok_body(req_get(t, tid, "/Settings"))

  # ─── Statutory Leave ─────────────────────────────────────────────────────────

  def statutory_leave_summary(%Token{} = t, tid, employee_id, opts \\ []) do
    ok_body(
      req_get(t, tid, "/StatutoryLeaves/Summary/#{employee_id}", %{
        "activeOnly" => opts[:active_only]
      })
    )
  end

  @doc "Creates a statutory leave record (e.g. parental leave)."
  def create_statutory_leave(%Token{} = t, tid, attrs),
    do: ok_body(post(t, tid, "/StatutoryLeaves", attrs))

  @doc "Returns statutory leave periods for an employee."
  def get_statutory_leave_periods(%Token{} = t, tid, statutory_leave_id),
    do: ok_body(req_get(t, tid, "/StatutoryLeaves/#{statutory_leave_id}/LeavePeriods"))
end
