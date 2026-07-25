defmodule Xero.PracticeManagerTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.PracticeManager

  # Practice Manager returns XML — stub with XML body
  defp stub_pm(bypass, method, path, status, xml_body) do
    Bypass.stub(bypass, method, path, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/xml")
      |> Plug.Conn.resp(status, xml_body)
    end)
  end

  describe "list_jobs/3" do
    test "returns raw XML on success", %{bypass: bypass, token: token, tenant_id: tid} do
      xml =
        "<Response><Jobs><Job><ID>job-1</ID><Name>Annual Accounts</Name></Job></Jobs></Response>"

      stub_pm(bypass, "GET", "/practicemanager/3.1/job.api", 200, xml)

      assert {:ok, body} = PracticeManager.list_jobs(token, tid)
      assert is_binary(body)
      assert body =~ "job-1"
    end

    test "passes state filter param", %{bypass: bypass, token: token, tenant_id: tid} do
      Bypass.expect_once(bypass, "GET", "/practicemanager/3.1/job.api", fn conn ->
        assert conn.query_string =~ "state=InProgress"

        conn
        |> Plug.Conn.put_resp_content_type("application/xml")
        |> Plug.Conn.resp(200, "<Response><Jobs/></Response>")
      end)

      assert {:ok, _} = PracticeManager.list_jobs(token, tid, state: "InProgress")
    end
  end

  describe "get_job/3" do
    test "fetches job by ID", %{bypass: bypass, token: token, tenant_id: tid} do
      xml = "<Response><Job><ID>job-abc</ID></Job></Response>"

      Bypass.expect_once(bypass, "GET", "/practicemanager/3.1/job.api", fn conn ->
        assert conn.query_string =~ "jobid=job-abc"

        conn
        |> Plug.Conn.put_resp_content_type("application/xml")
        |> Plug.Conn.resp(200, xml)
      end)

      assert {:ok, body} = PracticeManager.get_job(token, tid, "job-abc")
      assert body =~ "job-abc"
    end
  end

  describe "create_job/3" do
    test "POSTs job data", %{bypass: bypass, token: token, tenant_id: tid} do
      xml = "<Response><Job><ID>new-job</ID></Job></Response>"

      Bypass.expect_once(bypass, "POST", "/practicemanager/3.1/job.api", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/xml")
        |> Plug.Conn.resp(200, xml)
      end)

      assert {:ok, body} =
               PracticeManager.create_job(token, tid, %{
                 "clientid" => "client-1",
                 "name" => "Annual Accounts 2024"
               })

      assert body =~ "new-job"
    end
  end

  describe "list_clients/3" do
    test "returns client list XML", %{bypass: bypass, token: token, tenant_id: tid} do
      xml =
        "<Response><Clients><Client><ID>c-1</ID><Name>Acme</Name></Client></Clients></Response>"

      stub_pm(bypass, "GET", "/practicemanager/3.1/client.api", 200, xml)

      assert {:ok, body} = PracticeManager.list_clients(token, tid)
      assert body =~ "Acme"
    end
  end

  describe "list_staff/3" do
    test "returns staff XML", %{bypass: bypass, token: token, tenant_id: tid} do
      xml =
        "<Response><Staff><StaffMember><ID>s-1</ID><Name>Alice</Name></StaffMember></Staff></Response>"

      stub_pm(bypass, "GET", "/practicemanager/3.1/staff.api", 200, xml)

      assert {:ok, body} = PracticeManager.list_staff(token, tid)
      assert body =~ "Alice"
    end
  end

  describe "create_time/3" do
    test "POSTs time entry", %{bypass: bypass, token: token, tenant_id: tid} do
      xml = "<Response><TimeEntry><ID>t-1</ID></TimeEntry></Response>"

      Bypass.expect_once(bypass, "POST", "/practicemanager/3.1/time.api", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/xml")
        |> Plug.Conn.resp(200, xml)
      end)

      assert {:ok, _} =
               PracticeManager.create_time(token, tid, %{
                 "jobid" => "job-1",
                 "staffid" => "staff-1",
                 "minutes" => 90
               })
    end
  end

  describe "list_tasks/3" do
    test "returns task types XML", %{bypass: bypass, token: token, tenant_id: tid} do
      xml =
        "<Response><Tasks><Task><ID>task-1</ID><Name>Preparation</Name></Task></Tasks></Response>"

      stub_pm(bypass, "GET", "/practicemanager/3.1/task.api", 200, xml)

      assert {:ok, body} = PracticeManager.list_tasks(token, tid)
      assert body =~ "Preparation"
    end
  end
end
