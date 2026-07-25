defmodule Xero.FinanceTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.Finance

  describe "bank_statements/3" do
    test "returns bank statement data", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/finance.xro/1.0/BankStatementsPlus/statements", 200, %{
        "data" => [],
        "pagination" => %{}
      })

      assert {:ok, _} = Finance.bank_statements(token, tid, bank_account_id: "acct-uuid")
    end
  end

  describe "cash_validation/3" do
    test "returns cash validation report", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/finance.xro/1.0/CashValidation", 200, %{"accounts" => []})

      assert {:ok, _} = Finance.cash_validation(token, tid, balance_date: "2024-01-31")
    end
  end

  describe "balance_sheet/3" do
    test "returns financial balance sheet", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/finance.xro/1.0/FinancialStatements/balanceSheet", 200, %{
        "reports" => []
      })

      assert {:ok, _} = Finance.balance_sheet(token, tid)
    end
  end

  describe "profit_and_loss/3" do
    test "returns P&L statement", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/finance.xro/1.0/FinancialStatements/profitAndLoss", 200, %{
        "reports" => []
      })

      assert {:ok, _} =
               Finance.profit_and_loss(token, tid, start_month: "2024-01", end_month: "2024-12")
    end
  end

  describe "user_activities/3" do
    test "returns user activity stats", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/finance.xro/1.0/AccountingActivities/userActivities", 200, %{
        "activities" => []
      })

      assert {:ok, _} = Finance.user_activities(token, tid, data_month: "2024-01")
    end
  end
end
