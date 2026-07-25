defmodule Xero.Accounting.ReportsTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.Accounting.Reports

  describe "profit_and_loss/3" do
    test "returns report data", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/Reports/ProfitAndLoss", 200, %{
        "Reports" => [%{"ReportName" => "ProfitAndLoss"}]
      })

      assert {:ok, %{"Reports" => [_]}} =
               Reports.profit_and_loss(token, tid, from_date: "2024-01-01", to_date: "2024-12-31")
    end
  end

  describe "balance_sheet/3" do
    test "returns balance sheet", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/Reports/BalanceSheet", 200, %{
        "Reports" => [%{"ReportName" => "BalanceSheet"}]
      })

      assert {:ok, %{"Reports" => [_]}} = Reports.balance_sheet(token, tid)
    end
  end

  describe "trial_balance/3" do
    test "returns trial balance", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/Reports/TrialBalance", 200, %{
        "Reports" => [%{"ReportName" => "TrialBalance"}]
      })

      assert {:ok, %{"Reports" => [_]}} = Reports.trial_balance(token, tid)
    end
  end

  describe "aged_receivables/4" do
    test "passes contactID param", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/api.xro/2.0/Reports/AgedReceivablesByContact",
        fn conn ->
          assert conn.query_string =~ "contactID=contact-123"

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, Jason.encode!(%{"Reports" => []}))
        end
      )

      assert {:ok, _} = Reports.aged_receivables(token, tid, "contact-123")
    end
  end

  describe "list/2" do
    test "returns available reports", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/Reports", 200, %{"Reports" => []})
      assert {:ok, _} = Reports.list(token, tid)
    end
  end

  describe "error handling" do
    test "returns :forbidden when user lacks report permissions", %{
      bypass: bypass,
      token: token,
      tenant_id: tid
    } do
      stub_xero(bypass, "GET", "/api.xro/2.0/Reports/ProfitAndLoss", 403, %{
        "Message" => "No reports role"
      })

      assert {:error, %Xero.Error{type: :forbidden}} = Reports.profit_and_loss(token, tid)
    end
  end
end
