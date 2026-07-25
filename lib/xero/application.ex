defmodule Xero.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: Xero.Finch, pools: finch_pools()},
      Xero.Auth.TokenStore,
      Xero.HTTP.RateLimiter,
      Xero.Telemetry
    ]

    opts = [strategy: :one_for_one, name: Xero.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp finch_pools do
    config = Application.get_all_env(:xero)

    %{
      "https://api.xero.com" => [
        size: config[:pool_size] || 10,
        count: config[:pool_count] || 4,
        conn_opts: [transport_opts: [timeout: config[:connect_timeout] || 10_000]]
      ],
      "https://identity.xero.com" => [size: 4, count: 1],
      "https://login.xero.com" => [size: 2, count: 1]
    }
  end
end
