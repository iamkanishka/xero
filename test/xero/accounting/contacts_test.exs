defmodule Xero.Accounting.ContactsTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.Accounting.Contacts

  describe "list/3" do
    test "returns contacts", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/Contacts", 200, Factory.contact_list(3))
      assert {:ok, %{"Contacts" => contacts}} = Contacts.list(token, tid)
      assert length(contacts) == 3
    end

    test "sends searchTerm param", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "GET", "/api.xro/2.0/Contacts", fn conn ->
        assert conn.query_string =~ "searchTerm"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(Factory.contact_list(1)))
      end)

      assert {:ok, _} = Contacts.list(token, tid, search_term: "Acme")
    end

    test "returns :forbidden on 403", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/Contacts", 403, %{})
      assert {:error, %Xero.Error{type: :forbidden}} = Contacts.list(token, tid)
    end
  end

  describe "get/3" do
    test "returns a single contact", %{bypass: bypass, token: token, tenant_id: tid} do
      c = Factory.contact()
      id = c["ContactID"]
      stub_xero(bypass, "GET", "/api.xro/2.0/Contacts/#{id}", 200, %{"Contacts" => [c]})
      assert {:ok, %{"Contacts" => [returned]}} = Contacts.get(token, tid, id)
      assert returned["ContactID"] == id
    end
  end

  describe "create/3" do
    test "sends PUT with Contacts array", %{bypass: bypass, token: token, tenant_id: tid} do
      c = Factory.contact()

      Bypass.expect_once(bypass, "PUT", "/api.xro/2.0/Contacts", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert is_list(Jason.decode!(body)["Contacts"])

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"Contacts" => [c]}))
      end)

      assert {:ok, %{"Contacts" => [_]}} = Contacts.create(token, tid, %{"Name" => "New Contact"})
    end
  end

  describe "update/4" do
    test "sends POST with ContactID in body", %{bypass: bypass, token: token, tenant_id: tid} do
      c = Factory.contact()
      id = c["ContactID"]

      Bypass.expect_once(bypass, "POST", "/api.xro/2.0/Contacts/#{id}", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        contact = hd(Jason.decode!(body)["Contacts"])
        assert contact["ContactID"] == id

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"Contacts" => [c]}))
      end)

      assert {:ok, _} = Contacts.update(token, tid, id, %{"EmailAddress" => "new@email.com"})
    end
  end

  describe "archive/3" do
    test "sets ContactStatus to ARCHIVED", %{bypass: bypass, token: token, tenant_id: tid} do
      id = "archive-me"

      Bypass.expect_once(bypass, "POST", "/api.xro/2.0/Contacts/#{id}", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        contact = hd(Jason.decode!(body)["Contacts"])
        assert contact["ContactStatus"] == "ARCHIVED"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"Contacts" => [%{"ContactID" => id}]}))
      end)

      assert {:ok, _} = Contacts.archive(token, tid, id)
    end
  end
end
