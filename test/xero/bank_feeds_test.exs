defmodule Xero.BankFeedsTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.BankFeeds

  describe "list_feed_connections/3" do
    test "returns connections", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/bankfeeds.xro/1.0/FeedConnections", 200, %{
        "items" => [%{"id" => "conn-1", "accountType" => "BANK"}],
        "pagination" => %{}
      })

      assert {:ok, _} = BankFeeds.list_feed_connections(token, tid)
    end
  end

  describe "create_feed_connection/3" do
    test "POSTs connection data", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "POST", "/bankfeeds.xro/1.0/FeedConnections", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert is_list(Jason.decode!(body)["items"])

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"items" => [%{"id" => "new-conn"}]}))
      end)

      assert {:ok, _} =
               BankFeeds.create_feed_connection(token, tid, %{
                 "accountToken" => "my-token",
                 "accountType" => "BANK",
                 "accountName" => "Business Cheque",
                 "accountNumber" => "123456789",
                 "currency" => "AUD"
               })
    end
  end

  describe "create_statements/3" do
    test "POSTs statement data", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "POST", "/bankfeeds.xro/1.0/Statements", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert is_list(Jason.decode!(body)["items"])

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"items" => []}))
      end)

      assert {:ok, _} =
               BankFeeds.create_statements(token, tid, %{
                 "feedConnectionId" => "conn-1",
                 "startDate" => "2024-01-01",
                 "endDate" => "2024-01-31",
                 "statementLines" => []
               })
    end
  end
end
