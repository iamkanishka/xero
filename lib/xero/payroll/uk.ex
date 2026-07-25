defmodule Xero.Payroll.UK do
  @moduledoc """
  Xero Payroll API – United Kingdom.
  Base URL: `https://api.xero.com/payroll.xro/2.0/`
  Scopes: `payroll.employees`, `payroll.payruns`, `payroll.payslip`, `payroll.settings`

  Covers UK HMRC RTI submissions, National Insurance, student loans, CIS deductions,
  and working patterns for non-standard schedules.
  """
  use Xero.API.Base, api: :payroll_uk

  # ─── Employees ──────────────────────────────────────────────────────────────

  def list_employees(%Token{} = t, tid, opts \\ []) do
    ok_body(req_get(t, tid, "/Employees", %{"page" => opts[:page], "filter" => opts[:filter]}))
  end

  def get_employee(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Employees/#{id}"))
  def create_employee(%Token{} = t, tid, attrs), do: ok_body(post(t, tid, "/Employees", attrs))

  def update_employee(%Token{} = t, tid, id, attrs),
    do: ok_body(put(t, tid, "/Employees/#{id}", attrs))

  def get_employee_tax(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/Employees/#{id}/Tax"))

  def update_employee_tax(%Token{} = t, tid, id, attrs),
    do: ok_body(post(t, tid, "/Employees/#{id}/Tax", attrs))

  def get_employee_ni(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/Employees/#{id}/NationalInsurance"))

  def update_employee_ni(%Token{} = t, tid, id, attrs),
    do: ok_body(post(t, tid, "/Employees/#{id}/NationalInsurance", attrs))

  def get_employee_payment(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/Employees/#{id}/PaymentMethod"))

  def update_employee_payment(%Token{} = t, tid, id, attrs),
    do: ok_body(post(t, tid, "/Employees/#{id}/PaymentMethod", attrs))

  @doc "Returns leave balances for a UK employee."
  def get_employee_leave_balances(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/Employees/#{id}/LeaveBalances"))

  @doc "Returns leave for a UK employee."
  def get_employee_leave(%Token{} = t, tid, id, opts \\ []) do
    ok_body(req_get(t, tid, "/Employees/#{id}/Leave", %{"page" => opts[:page]}))
  end

  @doc "Creates leave for a UK employee."
  def create_employee_leave(%Token{} = t, tid, id, attrs),
    do: ok_body(post(t, tid, "/Employees/#{id}/Leave", attrs))

  @doc "Updates leave for a UK employee."
  def update_employee_leave(%Token{} = t, tid, id, leave_id, attrs),
    do: ok_body(put(t, tid, "/Employees/#{id}/Leave/#{leave_id}", attrs))

  @doc "Deletes leave for a UK employee."
  def delete_employee_leave(%Token{} = t, tid, id, leave_id) do
    case req_delete(t, tid, "/Employees/#{id}/Leave/#{leave_id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @doc """
  Returns the working pattern for an employee.
  Working patterns improve payrun accuracy for non-standard schedules.
  """
  def get_working_pattern(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/Employees/#{id}/WorkingPattern"))

  def update_working_pattern(%Token{} = t, tid, id, attrs),
    do: ok_body(post(t, tid, "/Employees/#{id}/WorkingPattern", attrs))

  # ─── Pay Runs ────────────────────────────────────────────────────────────────

  def list_pay_runs(%Token{} = t, tid, opts \\ []) do
    ok_body(req_get(t, tid, "/PayRuns", %{"page" => opts[:page], "status" => opts[:status]}))
  end

  def get_pay_run(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/PayRuns/#{id}"))

  def create_pay_run(%Token{} = t, tid, attrs), do: ok_body(post(t, tid, "/PayRuns", attrs))

  def update_pay_run(%Token{} = t, tid, id, attrs),
    do: ok_body(put(t, tid, "/PayRuns/#{id}", attrs))

  @doc "Posts (finalises) a UK pay run."
  def post_pay_run(%Token{} = t, tid, id),
    do: ok_body(post(t, tid, "/PayRuns/#{id}/Post", %{}))

  @doc "Reverts a posted UK pay run."
  def revert_pay_run(%Token{} = t, tid, id),
    do: ok_body(post(t, tid, "/PayRuns/#{id}/Revert", %{}))

  @doc "Deletes a DRAFT UK pay run."
  def delete_pay_run(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/PayRuns/#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ─── Pay Run Calendars ───────────────────────────────────────────────────────

  def list_pay_run_calendars(%Token{} = t, tid, opts \\ []) do
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

  # ─── Reimbursements ──────────────────────────────────────────────────────────

  def list_reimbursements(%Token{} = t, tid, opts \\ []) do
    ok_body(req_get(t, tid, "/Reimbursements", %{"page" => opts[:page]}))
  end

  def create_reimbursement(%Token{} = t, tid, attrs),
    do: ok_body(post(t, tid, "/Reimbursements", attrs))

  def update_reimbursement(%Token{} = t, tid, id, attrs),
    do: ok_body(put(t, tid, "/Reimbursements/#{id}", attrs))

  # ─── Leave Types ─────────────────────────────────────────────────────────────

  def list_leave_types(%Token{} = t, tid, opts \\ []) do
    ok_body(req_get(t, tid, "/LeaveTypes", %{"page" => opts[:page]}))
  end

  def get_leave_type(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/LeaveTypes/#{id}"))
  def create_leave_type(%Token{} = t, tid, attrs), do: ok_body(post(t, tid, "/LeaveTypes", attrs))

  def update_leave_type(%Token{} = t, tid, id, attrs),
    do: ok_body(put(t, tid, "/LeaveTypes/#{id}", attrs))

  # ─── Settings ────────────────────────────────────────────────────────────────

  def settings(%Token{} = t, tid), do: ok_body(req_get(t, tid, "/Settings"))

  # ─── Statutory Leave ─────────────────────────────────────────────────────────

  def statutory_leave(%Token{} = t, tid, employee_id),
    do: ok_body(req_get(t, tid, "/StatutoryLeaves/#{employee_id}"))

  @doc "Creates a statutory leave record (SMP, SPP, SAP, ShPP, etc.)."
  def create_statutory_leave(%Token{} = t, tid, attrs),
    do: ok_body(post(t, tid, "/StatutoryLeaves", attrs))

  @doc "Deletes a statutory leave record."
  def delete_statutory_leave(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/StatutoryLeaves/#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @doc "Returns statutory leave periods for a leave record."
  def get_statutory_leave_periods(%Token{} = t, tid, statutory_leave_id),
    do: ok_body(req_get(t, tid, "/StatutoryLeaves/#{statutory_leave_id}/LeavePeriods"))

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
end
