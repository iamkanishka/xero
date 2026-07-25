defmodule Xero.PracticeManager do
  @moduledoc """
  Xero Practice Manager API v3.1 – Accounting practice workflow management.
  Base URL: `https://api.xero.com/practicemanager/3.1/`
  Scope: `practicemanager`

  ⚠️  All responses are XML regardless of input content type.
  Raw XML string is returned from all functions.

  ## Job Status Values

  `"Prospect"` | `"NotStarted"` | `"InProgress"` | `"Overdue"`
  | `"Completed"` | `"Cancelled"`

  ## Priority Values

  `"Low"` | `"Normal"` | `"High"`
  """
  use Xero.API.Base, api: :practice_manager

  # Override: return raw body (XML)
  @spec ok_xml(Client.result()) :: {:ok, term()} | {:error, Error.t()}
  defp ok_xml(result), do: Runtime.ok_xml(result)

  # ─── Jobs ────────────────────────────────────────────────────────────────────

  @doc """
  Lists jobs with optional filters.
  Options: `:state`, `:client_id`, `:staff_id`, `:page`, `:due_date`,
  `:from`, `:to`, `:job_number`, `:detailed`
  """
  def list_jobs(%Token{} = t, tid, opts \\ []) do
    ok_xml(
      req_get(t, tid, "/job.api", %{
        "state" => opts[:state],
        "clientid" => opts[:client_id],
        "staffid" => opts[:staff_id],
        "page" => opts[:page],
        "duedate" => opts[:due_date],
        "from" => opts[:from],
        "to" => opts[:to],
        "jobnumber" => opts[:job_number],
        "detailed" => opts[:detailed]
      })
    )
  end

  def get_job(%Token{} = t, tid, id), do: ok_xml(req_get(t, tid, "/job.api", %{"jobid" => id}))

  @doc """
  Creates a new job.
  Required: `client_id`, `name`.
  Optional: `assigned_to`, `due_date`, `budget_minutes`, `category_id`, `type_id`, `priority`.
  """
  def create_job(%Token{} = t, tid, attrs), do: ok_xml(post(t, tid, "/job.api", attrs))

  def update_job(%Token{} = t, tid, id, attrs),
    do: ok_xml(post(t, tid, "/job.api", Map.put(attrs, "jobid", id)))

  def update_job_state(%Token{} = t, tid, id, state) do
    ok_xml(post(t, tid, "/job.api", %{"jobid" => id, "state" => state}))
  end

  @doc "Deletes a job."
  def delete_job(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/job.api?jobid=#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ─── Job Notes ───────────────────────────────────────────────────────────────

  def list_job_notes(%Token{} = t, tid, id),
    do: ok_xml(req_get(t, tid, "/jobnote.api", %{"jobid" => id}))

  def create_job_note(%Token{} = t, tid, attrs), do: ok_xml(post(t, tid, "/jobnote.api", attrs))

  def update_job_note(%Token{} = t, tid, id, attrs),
    do: ok_xml(post(t, tid, "/jobnote.api", Map.put(attrs, "jobnoteid", id)))

  def delete_job_note(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/jobnote.api?jobnoteid=#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ─── Job Costs ───────────────────────────────────────────────────────────────

  def list_job_costs(%Token{} = t, tid, job_id),
    do: ok_xml(req_get(t, tid, "/cost.api", %{"jobid" => job_id}))

  def create_job_cost(%Token{} = t, tid, attrs), do: ok_xml(post(t, tid, "/cost.api", attrs))

  def update_job_cost(%Token{} = t, tid, id, attrs),
    do: ok_xml(post(t, tid, "/cost.api", Map.put(attrs, "costid", id)))

  def delete_job_cost(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/cost.api?costid=#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ─── Clients ─────────────────────────────────────────────────────────────────

  def list_clients(%Token{} = t, tid, opts \\ []) do
    ok_xml(
      req_get(t, tid, "/client.api", %{
        "page" => opts[:page],
        "name" => opts[:name],
        "email" => opts[:email]
      })
    )
  end

  def get_client(%Token{} = t, tid, id),
    do: ok_xml(req_get(t, tid, "/client.api", %{"clientid" => id}))

  def create_client(%Token{} = t, tid, attrs), do: ok_xml(post(t, tid, "/client.api", attrs))

  def update_client(%Token{} = t, tid, id, attrs),
    do: ok_xml(post(t, tid, "/client.api", Map.put(attrs, "clientid", id)))

  def delete_client(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/client.api?clientid=#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ─── Staff ───────────────────────────────────────────────────────────────────

  def list_staff(%Token{} = t, tid, opts \\ []) do
    ok_xml(req_get(t, tid, "/staff.api", %{"includeArchived" => opts[:include_archived]}))
  end

  def get_staff(%Token{} = t, tid, id),
    do: ok_xml(req_get(t, tid, "/staff.api", %{"staffid" => id}))

  def create_staff(%Token{} = t, tid, attrs), do: ok_xml(post(t, tid, "/staff.api", attrs))

  def update_staff(%Token{} = t, tid, id, attrs),
    do: ok_xml(post(t, tid, "/staff.api", Map.put(attrs, "staffid", id)))

  # ─── Time ────────────────────────────────────────────────────────────────────

  def list_time(%Token{} = t, tid, opts \\ []) do
    ok_xml(
      req_get(t, tid, "/time.api", %{
        "jobid" => opts[:job_id],
        "staffid" => opts[:staff_id],
        "from" => opts[:from],
        "to" => opts[:to],
        "page" => opts[:page]
      })
    )
  end

  def create_time(%Token{} = t, tid, attrs), do: ok_xml(post(t, tid, "/time.api", attrs))

  def update_time(%Token{} = t, tid, id, attrs),
    do: ok_xml(post(t, tid, "/time.api", Map.put(attrs, "timeid", id)))

  def delete_time(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/time.api?timeid=#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ─── Tasks ───────────────────────────────────────────────────────────────────

  def list_tasks(%Token{} = t, tid, opts \\ []) do
    ok_xml(req_get(t, tid, "/task.api", %{"includeArchived" => opts[:include_archived]}))
  end

  def create_task(%Token{} = t, tid, attrs), do: ok_xml(post(t, tid, "/task.api", attrs))

  def update_task(%Token{} = t, tid, id, attrs),
    do: ok_xml(post(t, tid, "/task.api", Map.put(attrs, "taskid", id)))

  def delete_task(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/task.api?taskid=#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ─── Categories ──────────────────────────────────────────────────────────────

  def list_categories(%Token{} = t, tid), do: ok_xml(req_get(t, tid, "/category.api"))
  def create_category(%Token{} = t, tid, attrs), do: ok_xml(post(t, tid, "/category.api", attrs))

  def update_category(%Token{} = t, tid, id, attrs),
    do: ok_xml(post(t, tid, "/category.api", Map.put(attrs, "categoryid", id)))

  def delete_category(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/category.api?categoryid=#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ─── Templates ───────────────────────────────────────────────────────────────

  def list_templates(%Token{} = t, tid), do: ok_xml(req_get(t, tid, "/template.api"))
  def create_template(%Token{} = t, tid, attrs), do: ok_xml(post(t, tid, "/template.api", attrs))

  def update_template(%Token{} = t, tid, id, attrs),
    do: ok_xml(post(t, tid, "/template.api", Map.put(attrs, "templateid", id)))

  def delete_template(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/template.api?templateid=#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ─── Invoices ────────────────────────────────────────────────────────────────

  @doc "Exports invoices for a date range."
  def export_invoices(%Token{} = t, tid, opts \\ []) do
    ok_xml(
      req_get(t, tid, "/invoice.api", %{
        "from" => opts[:from],
        "to" => opts[:to],
        "jobid" => opts[:job_id],
        "clientid" => opts[:client_id]
      })
    )
  end
end
