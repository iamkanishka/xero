defmodule Xero.Projects do
  @moduledoc """
  Xero Projects API – Project, task, time, and project item management.
  Base URL: `https://api.xero.com/projects.xro/2.0/`
  Scopes: `projects` or `projects.read`
  Status flow: INPROGRESS → CLOSED (irreversible) | CANCELLED
  """
  use Xero.API.Base, api: :projects

  # ─── Projects ────────────────────────────────────────────────────────────────

  def list_projects(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Projects", %{
        "states" => opts[:states],
        "contactID" => opts[:contact_id],
        "page" => opts[:page],
        "pageSize" => opts[:page_size]
      })
    )
  end

  def get_project(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Projects/#{id}"))

  @doc """
  Creates a new project.
  Required: `name`, `contact_id`. Optional: `deadline_utc`, `estimate_amount`, `currency_code`.
  """
  def create_project(%Token{} = t, tid, attrs), do: ok_body(post(t, tid, "/Projects", attrs))

  def update_project(%Token{} = t, tid, id, attrs),
    do: ok_body(put(t, tid, "/Projects/#{id}", attrs))

  def close_project(%Token{} = t, tid, id) do
    case patch_status(t, tid, id, "CLOSED") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  def cancel_project(%Token{} = t, tid, id) do
    case patch_status(t, tid, id, "CANCELLED") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ─── Tasks ───────────────────────────────────────────────────────────────────

  @doc """
  Lists tasks for a project.
  Options: `:page`, `:page_size`, `:task_ids`, `:charge_type`
  charge_type values: `"TIME"` | `"FIXED"` | `"NON_CHARGEABLE"`
  """
  def list_tasks(%Token{} = t, tid, project_id, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Projects/#{project_id}/Tasks", %{
        "page" => opts[:page],
        "pageSize" => opts[:page_size],
        "taskIds" => format_list(opts[:task_ids]),
        "chargeType" => opts[:charge_type]
      })
    )
  end

  def get_task(%Token{} = t, tid, project_id, task_id),
    do: ok_body(req_get(t, tid, "/Projects/#{project_id}/Tasks/#{task_id}"))

  @doc """
  Creates a task. Required: `name`, `charge_type`.
  For TIME tasks, optionally set `rate` and `estimate_minutes`.
  """
  def create_task(%Token{} = t, tid, project_id, attrs),
    do: ok_body(post(t, tid, "/Projects/#{project_id}/Tasks", attrs))

  def update_task(%Token{} = t, tid, project_id, task_id, attrs),
    do: ok_body(put(t, tid, "/Projects/#{project_id}/Tasks/#{task_id}", attrs))

  @doc "Deletes a task (only if no time has been logged against it)."
  def delete_task(%Token{} = t, tid, project_id, task_id) do
    case req_delete(t, tid, "/Projects/#{project_id}/Tasks/#{task_id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ─── Time Entries ────────────────────────────────────────────────────────────

  @doc """
  Lists time entries. Options: `:user_id`, `:task_id`, `:invoice_id`,
  `:is_chargeable`, `:date_after_utc`, `:date_before_utc`, `:page`, `:page_size`
  """
  def list_time(%Token{} = t, tid, project_id, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Projects/#{project_id}/Time", %{
        "userId" => opts[:user_id],
        "taskId" => opts[:task_id],
        "invoiceId" => opts[:invoice_id],
        "isChargeable" => opts[:is_chargeable],
        "dateAfterUtc" => opts[:date_after_utc],
        "dateBeforeUtc" => opts[:date_before_utc],
        "page" => opts[:page],
        "pageSize" => opts[:page_size]
      })
    )
  end

  def get_time(%Token{} = t, tid, project_id, time_id),
    do: ok_body(req_get(t, tid, "/Projects/#{project_id}/Time/#{time_id}"))

  @doc """
  Logs a time entry. Required: `user_id`, `task_id`, `date_utc`, `duration` (minutes).
  Optional: `description`.
  """
  def create_time(%Token{} = t, tid, project_id, attrs),
    do: ok_body(post(t, tid, "/Projects/#{project_id}/Time", attrs))

  def update_time(%Token{} = t, tid, project_id, time_id, attrs),
    do: ok_body(put(t, tid, "/Projects/#{project_id}/Time/#{time_id}", attrs))

  def delete_time(%Token{} = t, tid, project_id, time_id) do
    case req_delete(t, tid, "/Projects/#{project_id}/Time/#{time_id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ─── Project Items (Expenses & Products) ─────────────────────────────────────

  @doc "Lists project items (non-time charges: expenses, products)."
  def list_items(%Token{} = t, tid, project_id, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Projects/#{project_id}/ProjectItems", %{
        "page" => opts[:page],
        "pageSize" => opts[:page_size]
      })
    )
  end

  def get_item(%Token{} = t, tid, project_id, item_id),
    do: ok_body(req_get(t, tid, "/Projects/#{project_id}/ProjectItems/#{item_id}"))

  @doc """
  Creates a project item.
  Required: `task_id`, `unit_amount`, `quantity`.
  Optional: `code`, `description`, `date_utc`, `account_code`.
  """
  def create_item(%Token{} = t, tid, project_id, attrs),
    do: ok_body(post(t, tid, "/Projects/#{project_id}/ProjectItems", attrs))

  def update_item(%Token{} = t, tid, project_id, item_id, attrs),
    do: ok_body(put(t, tid, "/Projects/#{project_id}/ProjectItems/#{item_id}", attrs))

  @doc "Deletes a project item."
  def delete_item(%Token{} = t, tid, project_id, item_id) do
    case req_delete(t, tid, "/Projects/#{project_id}/ProjectItems/#{item_id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ─── Users ───────────────────────────────────────────────────────────────────

  @doc "Lists users who can be assigned to projects in this organisation."
  def list_users(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/ProjectsUsers", %{"page" => opts[:page], "pageSize" => opts[:page_size]})
    )
  end

  # ─── Private ─────────────────────────────────────────────────────────────────

  defp patch_status(%Token{} = t, tid, id, status) do
    Client.post(
      url("/Projects/#{id}"),
      %{"status" => status},
      t,
      [{"x-http-method-override", "PATCH"}],
      tenant_id: tid
    )
  end
end
