defmodule Xero.HTTP.RateLimiter do
  @moduledoc """
  Per-tenant rate limit tracking (token bucket, ETS-backed).

  Tracks Xero's limits:
  - 60 requests/minute per tenant
  - 5,000 requests/day per tenant

  Returns `:ok` when the request may proceed,
  or `{:wait, ms}` when a limit is exhausted.
  """

  use GenServer

  @table :xero_rate_limits
  @day_limit 5_000
  @min_limit 60

  def start_link(opts \\ []),
    do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @spec track_request(String.t()) :: :ok | {:wait, pos_integer()}
  def track_request(tenant_id) do
    now = System.system_time(:second)
    bucket = div(now, 60)
    GenServer.call(__MODULE__, {:track, tenant_id, bucket})
  end

  @spec update_from_headers(String.t(), list()) :: :ok
  def update_from_headers(tenant_id, headers) do
    day = get_header(headers, "x-daylimit-remaining")
    min = get_header(headers, "x-minlimit-remaining")

    if day || min,
      do: GenServer.cast(__MODULE__, {:update_headers, tenant_id, parse_int(day), parse_int(min)})

    :ok
  end

  @spec get_state(String.t()) :: map()
  def get_state(tenant_id) do
    case :ets.lookup(@table, tenant_id) do
      [{_, s}] -> s
      [] -> %{day_used: 0, min_used: 0, day_remaining: @day_limit, min_remaining: @min_limit}
    end
  end

  @impl true
  def init(_) do
    :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
    {:ok, %{}}
  end

  @impl true
  def handle_call({:track, tenant_id, bucket}, _from, state) do
    cur = get_or_init(tenant_id, bucket)
    now_ms = System.system_time(:millisecond)

    cond do
      cur.day_used >= @day_limit ->
        ms = ms_until_midnight()
        {:reply, {:wait, ms}, state}

      cur.min_bucket == bucket && cur.min_used >= @min_limit ->
        ms = ms_until_next_minute()
        {:reply, {:wait, ms}, state}

      true ->
        min_used = if cur.min_bucket == bucket, do: cur.min_used + 1, else: 1

        updated = %{
          cur
          | day_used: cur.day_used + 1,
            min_used: min_used,
            min_bucket: bucket,
            last_request_ms: now_ms
        }

        :ets.insert(@table, {tenant_id, updated})
        {:reply, :ok, state}
    end
  end

  @impl true
  def handle_cast({:update_headers, tenant_id, day, min}, state) do
    cur = get_or_init(tenant_id, current_bucket())

    updated =
      cur
      |> maybe_put(:day_remaining, day)
      |> maybe_put(:min_remaining, min)

    :ets.insert(@table, {tenant_id, updated})
    {:noreply, state}
  end

  defp get_or_init(tenant_id, bucket) do
    case :ets.lookup(@table, tenant_id) do
      [{_, s}] ->
        s

      [] ->
        s = %{
          day_used: 0,
          min_used: 0,
          min_bucket: bucket,
          day_remaining: @day_limit,
          min_remaining: @min_limit,
          last_request_ms: 0
        }

        :ets.insert(@table, {tenant_id, s})
        s
    end
  end

  defp current_bucket, do: div(System.system_time(:second), 60)
  defp maybe_put(m, _k, nil), do: m
  defp maybe_put(m, k, v), do: Map.put(m, k, v)
  defp get_header(h, n), do: (List.keyfind(h || [], n, 0) || {nil, nil}) |> elem(1)
  defp parse_int(nil), do: nil
  defp parse_int(s) when is_binary(s), do: String.to_integer(s)
  defp parse_int(n), do: n

  defp ms_until_next_minute do
    now = System.system_time(:second)
    (60 - rem(now, 60)) * 1_000
  end

  defp ms_until_midnight do
    now = DateTime.utc_now()
    tomorrow = DateTime.new!(Date.add(DateTime.to_date(now), 1), ~T[00:00:00], "Etc/UTC")
    DateTime.diff(tomorrow, now, :millisecond)
  end
end
