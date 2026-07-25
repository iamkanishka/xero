defmodule Xero.Accounting.InvoicesTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.Accounting.Invoices

  describe "list/3" do
    test "returns invoices on 200", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/Invoices", 200, Factory.invoice_list(2))
      assert {:ok, %{"Invoices" => invoices}} = Invoices.list(token, tid)
      assert length(invoices) == 2
    end

    test "passes page param in query string", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "GET", "/api.xro/2.0/Invoices", fn conn ->
        assert conn.query_string =~ "page=2"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(Factory.invoice_list(1)))
      end)

      assert {:ok, _} = Invoices.list(token, tid, page: 2)
    end

    test "passes Statuses filter", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "GET", "/api.xro/2.0/Invoices", fn conn ->
        assert conn.query_string =~ "AUTHORISED"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(Factory.invoice_list(1)))
      end)

      assert {:ok, _} = Invoices.list(token, tid, statuses: ["AUTHORISED"])
    end

    test "returns :not_found on 404", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/Invoices", 404, %{})
      assert {:error, %Xero.Error{type: :not_found}} = Invoices.list(token, tid)
    end

    test "returns :unprocessable on 422 with message", %{
      bypass: bypass,
      token: token,
      tenant_id: tid
    } do
      stub_xero(bypass, "GET", "/api.xro/2.0/Invoices", 422, %{"Message" => "Validation failed"})

      assert {:error, %Xero.Error{type: :unprocessable, message: "Validation failed"}} =
               Invoices.list(token, tid)
    end

    test "returns :server_error on 500", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/Invoices", 500, %{})
      assert {:error, %Xero.Error{type: :server_error}} = Invoices.list(token, tid)
    end

    test "returns :forbidden on 403", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/Invoices", 403, %{"Message" => "Forbidden"})
      assert {:error, %Xero.Error{type: :forbidden}} = Invoices.list(token, tid)
    end
  end

  describe "get/4" do
    test "returns a single invoice by ID", %{bypass: bypass, token: token, tenant_id: tid} do
      inv = Factory.invoice()
      id = inv["InvoiceID"]
      stub_xero(bypass, "GET", "/api.xro/2.0/Invoices/#{id}", 200, %{"Invoices" => [inv]})
      assert {:ok, %{"Invoices" => [returned]}} = Invoices.get(token, tid, id)
      assert returned["InvoiceID"] == id
    end

    test "returns :not_found for unknown ID", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/Invoices/ghost", 404, %{})
      assert {:error, %Xero.Error{type: :not_found}} = Invoices.get(token, tid, "ghost")
    end
  end

  describe "create/4" do
    test "sends PUT with Invoices array", %{bypass: bypass, token: token, tenant_id: tid} do
      inv = Factory.invoice()

      Bypass.expect_once(bypass, "PUT", "/api.xro/2.0/Invoices", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert is_list(Jason.decode!(body)["Invoices"])

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"Invoices" => [inv]}))
      end)

      assert {:ok, %{"Invoices" => [_]}} =
               Invoices.create(token, tid, %{"Type" => "ACCREC", "LineItems" => []})
    end

    test "accepts a list of up to 50 invoices", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "PUT", "/api.xro/2.0/Invoices", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert length(Jason.decode!(body)["Invoices"]) == 3

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"Invoices" => []}))
      end)

      assert {:ok, _} =
               Invoices.create(token, tid, [
                 Factory.invoice(),
                 Factory.invoice(),
                 Factory.invoice()
               ])
    end
  end

  describe "void/3" do
    test "posts VOIDED status via POST", %{bypass: bypass, token: token, tenant_id: tid} do
      inv = Factory.invoice(%{"Status" => "VOIDED"})
      id = inv["InvoiceID"]

      Bypass.expect_once(bypass, "POST", "/api.xro/2.0/Invoices/#{id}", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert hd(Jason.decode!(body)["Invoices"])["Status"] == "VOIDED"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"Invoices" => [inv]}))
      end)

      assert {:ok, _} = Invoices.void(token, tid, id)
    end
  end

  describe "email/3" do
    test "returns :ok on 204", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "POST", "/api.xro/2.0/Invoices/inv-abc/Email", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok = Invoices.email(token, tid, "inv-abc")
    end
  end

  describe "history/3" do
    test "returns history records", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/Invoices/inv-hist/History", 200, %{
        "HistoryRecords" => [%{"Details" => "Invoice authorised"}]
      })

      assert {:ok, %{"HistoryRecords" => [%{"Details" => "Invoice authorised"}]}} =
               Invoices.history(token, tid, "inv-hist")
    end
  end

  describe "add_note/4" do
    test "sends PUT with HistoryRecords", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "PUT", "/api.xro/2.0/Invoices/inv-note/History", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        records = Jason.decode!(body)["HistoryRecords"]
        assert hd(records)["Details"] == "Payment received"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"HistoryRecords" => records}))
      end)

      assert {:ok, _} = Invoices.add_note(token, tid, "inv-note", "Payment received")
    end
  end
end
