defmodule Xero.Accounting.ManualJournalsTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.Accounting.ManualJournals

  describe "list/3" do
    test "returns manual journals", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/ManualJournals", 200, %{
        "ManualJournals" => [%{"ManualJournalID" => "mj-1", "Status" => "DRAFT"}]
      })

      assert {:ok, %{"ManualJournals" => [_]}} = ManualJournals.list(token, tid)
    end

    test "passes page param", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "GET", "/api.xro/2.0/ManualJournals", fn conn ->
        assert conn.query_string =~ "page=3"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"ManualJournals" => []}))
      end)

      assert {:ok, _} = ManualJournals.list(token, tid, page: 3)
    end
  end

  describe "create/3" do
    test "PUTs journal", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "PUT", "/api.xro/2.0/ManualJournals", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert is_list(Jason.decode!(body)["ManualJournals"])

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"ManualJournals" => []}))
      end)

      assert {:ok, _} =
               ManualJournals.create(token, tid, %{
                 "Narration" => "Depreciation entry",
                 "Date" => "2024-01-31",
                 "JournalLines" => []
               })
    end
  end
end
