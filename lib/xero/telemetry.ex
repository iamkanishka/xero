defmodule Xero.Telemetry do
  @moduledoc """
  Telemetry supervisor and default handler.

  ## Events emitted

  | Event | Measurements | Metadata |
  |-------|-------------|----------|
  | `[:xero, :http, :request]` | `duration` (native) | `method, url, status, tenant_id` |
  | `[:xero, :rate_limit, :remaining]` | `day_remaining, min_remaining, app_min_remaining` | `%{}` |
  | `[:xero, :auth, :token_refreshed]` | `%{}` | `%{}` |
  | `[:xero, :auth, :token_refresh_failed]` | `%{}` | `%{}` |

  ## Attaching your own handler

      :telemetry.attach_many("my-xero", [
        [:xero, :http, :request],
        [:xero, :rate_limit, :remaining]
      ], &MyApp.handle_xero_event/4, nil)

  ## telemetry_metrics integration

      [
        Telemetry.Metrics.summary("xero.http.request.duration", unit: {:native, :millisecond}, tags: [:status]),
        Telemetry.Metrics.last_value("xero.rate_limit.remaining.day_remaining"),
        Telemetry.Metrics.counter("xero.auth.token_refreshed")
      ]
  """

  use Supervisor
  require Logger

  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    attach_default_handlers()
    Supervisor.init([], strategy: :one_for_one)
  end

  @doc false
  def handle_event([:xero, :http, :request], %{duration: dur}, meta, _) do
    ms = System.convert_time_unit(dur, :native, :millisecond)

    Logger.debug(
      "[Xero] #{String.upcase(to_string(meta.method))} #{meta.url} → #{meta.status} (#{ms}ms)"
    )
  end

  def handle_event([:xero, :rate_limit, :remaining], %{day_remaining: day} = m, _, _) do
    if (day || 5_000) < 200,
      do:
        Logger.warning(
          "[Xero] Low on daily API calls: #{day} remaining (min: #{m.min_remaining})"
        )
  end

  def handle_event([:xero, :auth, :token_refreshed], _, _, _),
    do: Logger.debug("[Xero] Access token refreshed")

  def handle_event([:xero, :auth, :token_refresh_failed], _, _, _),
    do: Logger.warning("[Xero] Token refresh FAILED — user may need to re-authenticate")

  def handle_event(_, _, _, _), do: :ok

  defp attach_default_handlers do
    :telemetry.attach_many(
      "xero-default-logger",
      [
        [:xero, :http, :request],
        [:xero, :rate_limit, :remaining],
        [:xero, :auth, :token_refreshed],
        [:xero, :auth, :token_refresh_failed]
      ],
      &__MODULE__.handle_event/4,
      nil
    )
  end
end
