defmodule Xero.Accounting.ItemsTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.Accounting.Items

  describe "list/3" do
    test "returns items", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/Items", 200, %{
        "Items" => [%{"ItemID" => "item-1", "Code" => "SERV001"}]
      })

      assert {:ok, %{"Items" => [_]}} = Items.list(token, tid)
    end

    test "passes where filter", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "GET", "/api.xro/2.0/Items", fn conn ->
        assert conn.query_string =~ "where"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"Items" => []}))
      end)

      assert {:ok, _} = Items.list(token, tid, where: ~s(IsTrackedAsInventory == true))
    end
  end

  describe "create/3" do
    test "PUTs a new item", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "PUT", "/api.xro/2.0/Items", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        items = Jason.decode!(body)["Items"]
        assert hd(items)["Code"] == "PROD001"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"Items" => items}))
      end)

      assert {:ok, _} =
               Items.create(token, tid, %{
                 "Code" => "PROD001",
                 "Name" => "Product 001",
                 "Description" => "A product"
               })
    end
  end

  describe "delete/3" do
    test "DELETEs item and returns :ok", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "DELETE", "/api.xro/2.0/Items/item-del", fn conn ->
        Plug.Conn.resp(conn, 200, "{}")
      end)

      assert :ok = Items.delete(token, tid, "item-del")
    end
  end
end
