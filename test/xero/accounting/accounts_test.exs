defmodule Xero.Accounting.AccountsTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.Accounting.Accounts

  describe "list/3" do
    test "returns chart of accounts", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/Accounts", 200, %{
        "Accounts" => [Factory.account(), Factory.account()]
      })

      assert {:ok, %{"Accounts" => accounts}} = Accounts.list(token, tid)
      assert length(accounts) == 2
    end

    test "passes where filter param", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "GET", "/api.xro/2.0/Accounts", fn conn ->
        assert conn.query_string =~ "where"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"Accounts" => []}))
      end)

      assert {:ok, _} = Accounts.list(token, tid, where: ~s(Type == "SALES"))
    end
  end

  describe "create/3" do
    test "PUTs a new account", %{bypass: bypass, token: token, tenant_id: tid} do
      a = Factory.account()

      Bypass.expect_once(bypass, "PUT", "/api.xro/2.0/Accounts", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert is_list(Jason.decode!(body)["Accounts"])

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"Accounts" => [a]}))
      end)

      assert {:ok, %{"Accounts" => [_]}} =
               Accounts.create(token, tid, %{
                 "Code" => "400",
                 "Name" => "Income",
                 "Type" => "REVENUE"
               })
    end
  end

  describe "archive/3" do
    test "sets Status to ARCHIVED", %{bypass: bypass, token: token, tenant_id: tid} do
      id = "account-id-archive"

      Bypass.expect_once(bypass, "POST", "/api.xro/2.0/Accounts/#{id}", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert hd(Jason.decode!(body)["Accounts"])["Status"] == "ARCHIVED"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"Accounts" => []}))
      end)

      assert {:ok, _} = Accounts.archive(token, tid, id)
    end
  end
end
