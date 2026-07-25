defmodule Xero.Payroll.AUTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.Payroll.AU

  describe "list_employees/3" do
    test "returns employees", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/payroll.xro/1.0/Employees", 200, %{
        "Employees" => [%{"EmployeeID" => "emp-1", "FirstName" => "Jane"}]
      })

      assert {:ok, %{"Employees" => [_]}} = AU.list_employees(token, tid)
    end
  end

  describe "get_employee/3" do
    test "returns single employee", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/payroll.xro/1.0/Employees/emp-abc", 200, %{
        "Employees" => [%{"EmployeeID" => "emp-abc"}]
      })

      assert {:ok, _} = AU.get_employee(token, tid, "emp-abc")
    end
  end

  describe "list_pay_runs/3" do
    test "returns pay runs", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/payroll.xro/1.0/PayRuns", 200, %{
        "PayRuns" => [%{"PayRunID" => "pr-1"}]
      })

      assert {:ok, %{"PayRuns" => [_]}} = AU.list_pay_runs(token, tid)
    end
  end

  describe "settings/2" do
    test "returns payroll settings", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/payroll.xro/1.0/Settings", 200, %{"PayrollSettings" => %{}})

      assert {:ok, _} = AU.settings(token, tid)
    end
  end
end

defmodule Xero.Payroll.NZTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.Payroll.NZ

  describe "list_employees/3" do
    test "returns NZ employees", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/payrollnz.xro/1.0/Employees", 200, %{
        "employees" => [%{"employeeId" => "emp-nz-1"}]
      })

      assert {:ok, _} = NZ.list_employees(token, tid)
    end
  end

  describe "list_leave_types/3" do
    test "returns NZ leave types", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/payrollnz.xro/1.0/LeaveTypes", 200, %{"leaveTypes" => []})

      assert {:ok, _} = NZ.list_leave_types(token, tid)
    end
  end
end

defmodule Xero.Payroll.UKTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.Payroll.UK

  describe "list_employees/3" do
    test "returns UK employees", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/payroll.xro/2.0/Employees", 200, %{
        "employees" => [%{"employeeId" => "emp-uk-1"}]
      })

      assert {:ok, _} = UK.list_employees(token, tid)
    end
  end

  describe "get_working_pattern/3" do
    test "returns working pattern", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/payroll.xro/2.0/Employees/emp-uk-1/WorkingPattern", 200, %{
        "workingPatternID" => "wp-1"
      })

      assert {:ok, _} = UK.get_working_pattern(token, tid, "emp-uk-1")
    end
  end

  describe "get_employee_tax/3" do
    test "returns UK tax settings", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/payroll.xro/2.0/Employees/emp-uk-1/Tax", 200, %{
        "taxCode" => "1257L"
      })

      assert {:ok, _} = UK.get_employee_tax(token, tid, "emp-uk-1")
    end
  end
end
