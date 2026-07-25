defmodule Xero.ProjectsTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.Projects

  describe "list_projects/3" do
    test "returns projects list", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/projects.xro/2.0/Projects", 200, %{
        "items" => [Factory.project()],
        "pagination" => %{"pageCount" => 1}
      })

      assert {:ok, %{"items" => [_]}} = Projects.list_projects(token, tid)
    end
  end

  describe "create_project/3" do
    test "POSTs project data", %{bypass: bypass, token: token, tenant_id: tid} do
      p = Factory.project()

      Bypass.expect_once(bypass, "POST", "/projects.xro/2.0/Projects", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert Jason.decode!(body)["name"] != nil

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(p))
      end)

      assert {:ok, _} =
               Projects.create_project(token, tid, %{name: "New Project", contact_id: "c-uuid"})
    end
  end

  describe "create_time/4" do
    test "logs a time entry", %{bypass: bypass, token: token, tenant_id: tid} do
      project_id = "proj-abc"

      stub_xero(
        bypass,
        "POST",
        "/projects.xro/2.0/Projects/#{project_id}/Time",
        200,
        Factory.time_entry()
      )

      assert {:ok, _} =
               Projects.create_time(token, tid, project_id, %{
                 "userId" => "user-1",
                 "taskId" => "task-1",
                 "dateUtc" => "2024-01-15T09:00:00Z",
                 "duration" => 60
               })
    end
  end

  describe "list_tasks/4" do
    test "lists tasks for a project", %{bypass: bypass, token: token, tenant_id: tid} do
      project_id = "proj-tasks"

      stub_xero(bypass, "GET", "/projects.xro/2.0/Projects/#{project_id}/Tasks", 200, %{
        "items" => [Factory.task()]
      })

      assert {:ok, %{"items" => [_]}} = Projects.list_tasks(token, tid, project_id)
    end
  end
end
