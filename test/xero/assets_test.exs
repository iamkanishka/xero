defmodule Xero.AssetsTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.Assets

  describe "list/3" do
    test "lists assets with status filter", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "GET", "/assets.xro/1.0/Assets", fn conn ->
        assert conn.query_string =~ "status=REGISTERED"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(
          200,
          Jason.encode!(%{"items" => [Factory.asset()], "pagination" => %{}})
        )
      end)

      assert {:ok, _} = Assets.list(token, tid, status: "REGISTERED")
    end
  end

  describe "get/3" do
    test "retrieves an asset by ID", %{bypass: bypass, token: token, tenant_id: tid} do
      a = Factory.asset()
      id = a["assetId"]
      stub_xero(bypass, "GET", "/assets.xro/1.0/Assets/#{id}", 200, a)
      assert {:ok, _} = Assets.get(token, tid, id)
    end
  end

  describe "create/3" do
    test "POSTs asset to create endpoint", %{bypass: bypass, token: token, tenant_id: tid} do
      a = Factory.asset()

      Bypass.expect_once(bypass, "POST", "/assets.xro/1.0/Assets", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert is_map(Jason.decode!(body))

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(a))
      end)

      assert {:ok, _} =
               Assets.create(token, tid, %{"assetName" => "Laptop", "assetStatus" => "DRAFT"})
    end
  end

  describe "settings/2" do
    test "retrieves org asset settings", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/assets.xro/1.0/Settings", 200, %{"AssetNumberPrefix" => "FA"})
      assert {:ok, _} = Assets.settings(token, tid)
    end
  end
end
