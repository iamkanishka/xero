defmodule Xero.Accounting.CreditNotesTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.Accounting.CreditNotes

  describe "list/3" do
    test "returns credit notes", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/CreditNotes", 200, %{
        "CreditNotes" => [%{"CreditNoteID" => "cn-1", "Type" => "ACCRECCREDIT"}]
      })

      assert {:ok, %{"CreditNotes" => [_]}} = CreditNotes.list(token, tid)
    end
  end

  describe "create/3" do
    test "PUTs credit note", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "PUT", "/api.xro/2.0/CreditNotes", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert is_list(Jason.decode!(body)["CreditNotes"])

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"CreditNotes" => []}))
      end)

      assert {:ok, _} =
               CreditNotes.create(token, tid, %{
                 "Type" => "ACCRECCREDIT",
                 "Contact" => %{"ContactID" => "c-uuid"},
                 "LineItems" => []
               })
    end
  end

  describe "allocate/4" do
    test "PUTs allocation to credit note", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "PUT", "/api.xro/2.0/CreditNotes/cn-1/Allocations", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        allocs = Jason.decode!(body)["Allocations"]
        assert hd(allocs)["Amount"] == 50.0

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"Allocations" => allocs}))
      end)

      assert {:ok, _} =
               CreditNotes.allocate(token, tid, "cn-1", %{
                 "Invoice" => %{"InvoiceID" => "inv-uuid"},
                 "Amount" => 50.0
               })
    end
  end
end
