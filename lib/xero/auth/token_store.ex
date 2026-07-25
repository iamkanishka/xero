defmodule Xero.Auth.TokenStore do
  @moduledoc """
  ETS-backed GenServer for multi-tenant OAuth token storage with proactive refresh.

  Stores tokens per `{user_id, tenant_id}`. Background timer proactively
  refreshes tokens expiring within 5 minutes.

      :ok = Xero.Auth.TokenStore.put("user-123", "tenant-456", tokens)
      {:ok, tokens} = Xero.Auth.TokenStore.get("user-123", "tenant-456")
      :ok = Xero.Auth.TokenStore.delete("user-123", "tenant-456")
  """

  use GenServer
  require Logger

  alias Xero.Auth
  alias Xero.Auth.Token

  @table :xero_token_store

  def start_link(opts \\ []),
    do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @spec put(String.t(), String.t(), Token.t()) :: :ok
  def put(user_id, tenant_id, %Token{} = token) do
    :ets.insert(@table, {{user_id, tenant_id}, token})
    :ok
  end

  @spec get(String.t(), String.t()) :: {:ok, Token.t()} | {:error, :not_found | Xero.Error.t()}
  def get(user_id, tenant_id) do
    case :ets.lookup(@table, {user_id, tenant_id}) do
      [{{^user_id, ^tenant_id}, token}] ->
        if Auth.token_expired?(token),
          do: refresh_and_store(user_id, tenant_id, token),
          else: {:ok, token}

      [] ->
        {:error, :not_found}
    end
  end

  @spec delete(String.t(), String.t()) :: :ok
  def delete(user_id, tenant_id) do
    :ets.delete(@table, {user_id, tenant_id})
    :ok
  end

  @spec list_keys() :: list({String.t(), String.t()})
  def list_keys, do: Enum.map(:ets.tab2list(@table), fn {k, _} -> k end)

  @impl true
  def init(_opts) do
    :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
    schedule_check()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:check_expiring, state) do
    threshold = DateTime.add(DateTime.utc_now(), 300, :second)

    Enum.each(:ets.tab2list(@table), fn {{uid, tid}, %Token{expires_at: exp} = t} ->
      if DateTime.compare(exp, threshold) == :lt,
        do: Task.start(fn -> refresh_and_store(uid, tid, t) end)
    end)

    schedule_check()
    {:noreply, state}
  end

  @spec refresh_and_store(String.t(), String.t(), Token.t()) ::
          {:ok, Token.t()} | {:error, Xero.Error.t()}
  defp refresh_and_store(user_id, tenant_id, token) do
    case Auth.refresh_token(token.refresh_token) do
      {:ok, new_token} ->
        put(user_id, tenant_id, new_token)
        {:ok, new_token}

      {:error, error} ->
        Logger.warning(
          "[Xero.TokenStore] Refresh failed #{user_id}/#{tenant_id}: #{inspect(error)}"
        )

        {:error, error}
    end
  end

  defp schedule_check, do: Process.send_after(self(), :check_expiring, :timer.minutes(1))
end
