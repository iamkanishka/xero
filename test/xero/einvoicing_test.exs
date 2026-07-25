defmodule Xero.EInvoicingTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.EInvoicing

  describe "lookup_participant/3" do
    test "returns participant details", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "GET", "/einvoicing/documents/Participants", fn conn ->
        assert conn.query_string =~ "participantId"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"participantId" => "0151:12345678901"}))
      end)

      assert {:ok, _} = EInvoicing.lookup_participant(token, tid, "0151:12345678901")
    end
  end

  describe "list_documents/3" do
    test "returns documents list", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/einvoicing/documents", 200, %{
        "documents" => [],
        "pagination" => %{}
      })

      assert {:ok, _} = EInvoicing.list_documents(token, tid, direction: "SENT")
    end
  end

  describe "send_document/3" do
    test "POSTs invoice_id to send endpoint", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "POST", "/einvoicing/documents", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert Jason.decode!(body)["invoiceId"] == "inv-uuid"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"documentId" => "doc-1"}))
      end)

      assert {:ok, _} = EInvoicing.send_document(token, tid, %{"invoiceId" => "inv-uuid"})
    end
  end

  describe "get_document_status/3" do
    test "returns document status", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/einvoicing/documents/doc-1/status", 200, %{
        "status" => "DELIVERED"
      })

      assert {:ok, %{"status" => "DELIVERED"}} =
               EInvoicing.get_document_status(token, tid, "doc-1")
    end
  end

  describe "acknowledge_document/3" do
    test "returns :ok on 200", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "POST", "/einvoicing/documents/doc-ack/Acknowledge", fn conn ->
        Plug.Conn.resp(conn, 200, "{}")
      end)

      assert :ok = EInvoicing.acknowledge_document(token, tid, "doc-ack")
    end
  end
end
