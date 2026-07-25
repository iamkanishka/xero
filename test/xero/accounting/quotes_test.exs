defmodule Xero.Accounting.QuotesTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.Accounting.Quotes

  describe "list/3" do
    test "returns quotes", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/Quotes", 200, %{
        "Quotes" => [%{"QuoteID" => "q-1", "Status" => "DRAFT"}]
      })

      assert {:ok, %{"Quotes" => [_]}} = Quotes.list(token, tid)
    end

    test "filters by status and contact", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "GET", "/api.xro/2.0/Quotes", fn conn ->
        assert conn.query_string =~ "Status=SENT"
        assert conn.query_string =~ "ContactID=c-123"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"Quotes" => []}))
      end)

      assert {:ok, _} = Quotes.list(token, tid, status: "SENT", contact_id: "c-123")
    end
  end

  describe "create/3" do
    test "PUTs quote", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "PUT", "/api.xro/2.0/Quotes", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert is_list(Jason.decode!(body)["Quotes"])

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"Quotes" => [%{"QuoteID" => "new-q"}]}))
      end)

      assert {:ok, _} =
               Quotes.create(token, tid, %{
                 "Contact" => %{"ContactID" => "c-uuid"},
                 "LineItems" => [],
                 "Status" => "DRAFT"
               })
    end
  end
end
