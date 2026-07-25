defmodule Xero.FilesTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.Files

  describe "list/3" do
    test "returns files list", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/files.xro/1.0/Files", 200, [
        %{"FileId" => "file-1", "Name" => "invoice.pdf"}
      ])

      assert {:ok, _} = Files.list(token, tid)
    end
  end

  describe "folders/3" do
    test "returns folders", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/files.xro/1.0/Folders", 200, [
        %{"Id" => "folder-1", "Name" => "Invoices 2024"}
      ])

      assert {:ok, _} = Files.folders(token, tid)
    end
  end

  describe "create_folder/3" do
    test "POSTs folder name", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "POST", "/files.xro/1.0/Folders", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert Jason.decode!(body)["Name"] == "My Folder"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"Id" => "new-folder", "Name" => "My Folder"}))
      end)

      assert {:ok, _} = Files.create_folder(token, tid, "My Folder")
    end
  end

  describe "associations/3" do
    test "returns file associations for an object", %{
      bypass: bypass,
      token: token,
      tenant_id: tid
    } do
      obj_id = "some-invoice-id"

      stub_xero(bypass, "GET", "/files.xro/1.0/Associations/#{obj_id}", 200, [
        %{"FileId" => "f-1", "ObjectId" => obj_id}
      ])

      assert {:ok, _} = Files.associations(token, tid, obj_id)
    end
  end

  describe "inbox/2" do
    test "returns inbox folder", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/files.xro/1.0/Inbox", 200, %{
        "Id" => "inbox-id",
        "Name" => "Inbox"
      })

      assert {:ok, _} = Files.inbox(token, tid)
    end
  end
end
