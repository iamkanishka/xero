defmodule Xero.Accounting.HistoryTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.Accounting.History

  describe "get/4" do
    test "returns history for a valid resource", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/Invoices/inv-1/History", 200, %{
        "HistoryRecords" => [%{"Details" => "Created"}]
      })

      assert {:ok, %{"HistoryRecords" => [_]}} = History.get(token, tid, "Invoices", "inv-1")
    end

    test "returns :config_error for invalid resource type", %{token: token, tenant_id: tid} do
      assert {:error, %Xero.Error{type: :config_error}} =
               History.get(token, tid, "FakeResource", "some-id")
    end

    test "works for all 14 valid resource types", %{bypass: bypass, token: token, tenant_id: tid} do
      valid = ~w(Accounts BankTransactions BankTransfers Contacts CreditNotes
                 Invoices Items ManualJournals Overpayments Payments Prepayments
                 PurchaseOrders Quotes Receipts)

      Enum.each(valid, fn resource ->
        Bypass.stub(bypass, "GET", "/api.xro/2.0/#{resource}/res-id/History", fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, Jason.encode!(%{"HistoryRecords" => []}))
        end)

        assert {:ok, _} = History.get(token, tid, resource, "res-id"),
               "Expected success for resource: #{resource}"
      end)
    end
  end

  describe "add_note/5" do
    test "PUTs a history note", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "PUT", "/api.xro/2.0/Contacts/c-1/History", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        records = Jason.decode!(body)["HistoryRecords"]
        assert hd(records)["Details"] == "Called re overdue invoice"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"HistoryRecords" => records}))
      end)

      assert {:ok, _} =
               History.add_note(token, tid, "Contacts", "c-1", "Called re overdue invoice")
    end

    test "returns :config_error for invalid resource", %{token: token, tenant_id: tid} do
      assert {:error, %Xero.Error{type: :config_error}} =
               History.add_note(token, tid, "Widgets", "w-1", "note")
    end
  end
end
