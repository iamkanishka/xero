defmodule Xero.Accounting.TrackingCategoriesTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.Accounting.TrackingCategories

  describe "list/3" do
    test "returns tracking categories", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/TrackingCategories", 200, %{
        "TrackingCategories" => [%{"TrackingCategoryID" => "tc-1", "Name" => "Department"}]
      })

      assert {:ok, %{"TrackingCategories" => [_]}} = TrackingCategories.list(token, tid)
    end
  end

  describe "create/3" do
    test "PUTs a new tracking category", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "PUT", "/api.xro/2.0/TrackingCategories", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert is_list(Jason.decode!(body)["TrackingCategories"])

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"TrackingCategories" => []}))
      end)

      assert {:ok, _} = TrackingCategories.create(token, tid, %{"Name" => "Region"})
    end
  end

  describe "create_option/4" do
    test "PUTs option under category", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "PUT", "/api.xro/2.0/TrackingCategories/tc-1/Options", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        opts = Jason.decode!(body)["TrackingOptions"]
        assert hd(opts)["Name"] == "North"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"TrackingOptions" => [%{"Name" => "North"}]}))
      end)

      assert {:ok, _} = TrackingCategories.create_option(token, tid, "tc-1", "North")
    end
  end

  describe "delete/3" do
    test "DELETEs the category and returns :ok", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "DELETE", "/api.xro/2.0/TrackingCategories/tc-del", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{}))
      end)

      assert :ok = TrackingCategories.delete(token, tid, "tc-del")
    end
  end
end
