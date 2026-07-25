defmodule Xero.Accounting.PurchaseOrdersTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.Accounting.PurchaseOrders

  describe "list/3" do
    test "defaults to page=1", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "GET", "/api.xro/2.0/PurchaseOrders", fn conn ->
        assert conn.query_string =~ "page=1"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"PurchaseOrders" => []}))
      end)

      assert {:ok, _} = PurchaseOrders.list(token, tid)
    end

    test "filters by status", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "GET", "/api.xro/2.0/PurchaseOrders", fn conn ->
        assert conn.query_string =~ "Status=AUTHORISED"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"PurchaseOrders" => [Factory.purchase_order()]}))
      end)

      assert {:ok, %{"PurchaseOrders" => [_]}} =
               PurchaseOrders.list(token, tid, status: "AUTHORISED")
    end
  end

  describe "create/3" do
    test "PUTs purchase order", %{bypass: bypass, token: token, tenant_id: tid} do
      po = Factory.purchase_order()

      Bypass.expect_once(bypass, "PUT", "/api.xro/2.0/PurchaseOrders", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert is_list(Jason.decode!(body)["PurchaseOrders"])

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"PurchaseOrders" => [po]}))
      end)

      assert {:ok, _} =
               PurchaseOrders.create(token, tid, %{
                 "Contact" => %{"ContactID" => "c-uuid"},
                 "LineItems" => [],
                 "Date" => "2024-01-15"
               })
    end
  end
end
