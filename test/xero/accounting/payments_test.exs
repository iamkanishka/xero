defmodule Xero.Accounting.PaymentsTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.Accounting.Payments

  describe "list/3" do
    test "returns payments", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/Payments", 200, %{"Payments" => [Factory.payment()]})

      assert {:ok, %{"Payments" => [_]}} = Payments.list(token, tid)
    end

    test "defaults to page=1", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "GET", "/api.xro/2.0/Payments", fn conn ->
        assert conn.query_string =~ "page=1"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"Payments" => []}))
      end)

      assert {:ok, _} = Payments.list(token, tid)
    end
  end

  describe "create/3" do
    test "PUTs payment", %{bypass: bypass, token: token, tenant_id: tid} do
      p = Factory.payment()

      Bypass.expect_once(bypass, "PUT", "/api.xro/2.0/Payments", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert is_list(Jason.decode!(body)["Payments"])

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"Payments" => [p]}))
      end)

      assert {:ok, _} =
               Payments.create(token, tid, %{
                 "Invoice" => %{"InvoiceID" => "inv-uuid"},
                 "Account" => %{"Code" => "090"},
                 "Date" => "2024-01-15",
                 "Amount" => 110.0
               })
    end
  end

  describe "delete/3" do
    test "POSTs with DELETED status", %{bypass: bypass, token: token, tenant_id: tid} do
      id = "pay-delete-id"

      Bypass.expect_once(bypass, "POST", "/api.xro/2.0/Payments/#{id}", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert hd(Jason.decode!(body)["Payments"])["Status"] == "DELETED"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"Payments" => []}))
      end)

      assert {:ok, _} = Payments.delete(token, tid, id)
    end
  end
end
