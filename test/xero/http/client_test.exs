defmodule Xero.HTTP.ClientTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.HTTP.Client

  describe "get/4" do
    test "sends Authorization header", %{bypass: bypass, token: token} do
      Bypass.expect_once(bypass, "GET", "/api.xro/2.0/Invoices", fn conn ->
        auth = Plug.Conn.get_req_header(conn, "authorization")
        assert ["Bearer test-access-token-abc123"] = auth

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{}))
      end)

      base = "http://localhost:#{bypass.port}"
      Client.get("#{base}/api.xro/2.0/Invoices", token, [], tenant_id: Factory.tenant_id())
    end

    test "sends xero-tenant-id header when tenant_id is provided", %{
      bypass: bypass,
      token: token,
      tenant_id: tid
    } do
      Bypass.expect_once(bypass, "GET", "/api.xro/2.0/Invoices", fn conn ->
        tenant_header = Plug.Conn.get_req_header(conn, "xero-tenant-id")
        assert [^tid] = tenant_header

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{}))
      end)

      base = "http://localhost:#{bypass.port}"
      Client.get("#{base}/api.xro/2.0/Invoices", token, [], tenant_id: tid)
    end

    test "omits xero-tenant-id when skip_tenant: true", %{bypass: bypass, token: token} do
      Bypass.expect_once(bypass, "GET", "/connections", fn conn ->
        tenant_header = Plug.Conn.get_req_header(conn, "xero-tenant-id")
        assert [] = tenant_header

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!([]))
      end)

      base = "http://localhost:#{bypass.port}"
      Client.get("#{base}/connections", token, [], skip_tenant: true)
    end

    test "sends x-correlation-id header", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "GET", "/api.xro/2.0/Test", fn conn ->
        corr = Plug.Conn.get_req_header(conn, "x-correlation-id")
        assert length(corr) == 1
        assert String.length(hd(corr)) > 10

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{}))
      end)

      base = "http://localhost:#{bypass.port}"
      Client.get("#{base}/api.xro/2.0/Test", token, [], tenant_id: tid)
    end

    test "returns :network_error when server is down", %{
      bypass: bypass,
      token: token,
      tenant_id: tid
    } do
      Bypass.down(bypass)
      base = "http://localhost:#{bypass.port}"

      assert {:error, %Xero.Error{type: :network_error}} =
               Client.get("#{base}/api.xro/2.0/Invoices", token, [], tenant_id: tid)

      Bypass.up(bypass)
    end
  end

  describe "post/5" do
    test "sends JSON body", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "POST", "/api.xro/2.0/Invoices/inv-id", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert Jason.decode!(body) == %{"key" => "value"}

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{}))
      end)

      base = "http://localhost:#{bypass.port}"

      Client.post("#{base}/api.xro/2.0/Invoices/inv-id", %{"key" => "value"}, token, [],
        tenant_id: tid
      )
    end
  end

  describe "put/5" do
    test "sends JSON body via PUT", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "PUT", "/api.xro/2.0/Invoices", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert is_map(Jason.decode!(body))

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{}))
      end)

      base = "http://localhost:#{bypass.port}"
      Client.put("#{base}/api.xro/2.0/Invoices", %{"Invoices" => []}, token, [], tenant_id: tid)
    end
  end

  describe "base_url/1" do
    test "returns correct URLs for each API" do
      assert Client.base_url(:accounting) =~ "api.xro/2.0"
      assert Client.base_url(:assets) =~ "assets.xro/1.0"
      assert Client.base_url(:files) =~ "files.xro/1.0"
      assert Client.base_url(:finance) =~ "finance.xro/1.0"
      assert Client.base_url(:projects) =~ "projects.xro/2.0"
      assert Client.base_url(:payroll_au) =~ "payroll.xro/1.0"
      assert Client.base_url(:payroll_nz) =~ "payrollnz.xro/1.0"
      assert Client.base_url(:payroll_uk) =~ "payroll.xro/2.0"
      assert Client.base_url(:bankfeeds) =~ "bankfeeds.xro/1.0"
      assert Client.base_url(:appstore) =~ "appstore/2.0"
      assert Client.base_url(:einvoicing) =~ "einvoicing"
      assert Client.base_url(:practice_manager) =~ "practicemanager/3.1"
    end
  end
end
