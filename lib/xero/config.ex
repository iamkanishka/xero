defmodule Xero.Config do
  @moduledoc """
  NimbleOptions-validated configuration for the Xero client.

  ## Configuration Keys

  | Key | Type | Default | Description |
  |-----|------|---------|-------------|
  | `client_id` | string | **required** | Xero app Client ID |
  | `client_secret` | string | **required** | Xero app Client Secret |
  | `redirect_uri` | string | **required** | OAuth callback URL |
  | `scopes` | list(string) | `[openid, ...]` | Requested OAuth scopes |
  | `base_url` | string | `https://api.xero.com` | API base URL |
  | `identity_url` | string | `https://identity.xero.com` | Identity URL |
  | `timeout` | integer | `30_000` | Request timeout (ms) |
  | `connect_timeout` | integer | `10_000` | Connection timeout (ms) |
  | `pool_size` | integer | `10` | Finch pool size |
  | `pool_count` | integer | `4` | Number of Finch pools |
  | `max_retries` | integer | `3` | Retry attempts on failure |
  | `retry_base_delay` | integer | `1_000` | Base backoff delay (ms) |
  | `retry_max_delay` | integer | `30_000` | Max backoff delay (ms) |
  | `log_level` | atom | `:info` | Log level |
  """

  @schema NimbleOptions.new!(
            client_id: [type: :string, required: true, doc: "Xero app Client ID"],
            client_secret: [type: :string, required: true, doc: "Xero app Client Secret"],
            redirect_uri: [type: :string, required: true, doc: "OAuth2 redirect URI"],
            scopes: [
              type: {:list, :string},
              default:
                ~w(openid profile email accounting.transactions accounting.contacts offline_access),
              doc: "OAuth2 scopes to request"
            ],
            base_url: [type: :string, default: "https://api.xero.com", doc: "Xero API base URL"],
            identity_url: [
              type: :string,
              default: "https://identity.xero.com",
              doc: "Xero identity URL"
            ],
            timeout: [type: :non_neg_integer, default: 30_000, doc: "Request timeout (ms)"],
            connect_timeout: [
              type: :non_neg_integer,
              default: 10_000,
              doc: "Connection timeout (ms)"
            ],
            pool_size: [type: :non_neg_integer, default: 10, doc: "Finch connection pool size"],
            pool_count: [
              type: :non_neg_integer,
              default: 4,
              doc: "Number of Finch connection pools"
            ],
            max_retries: [type: :non_neg_integer, default: 3, doc: "Max retry attempts"],
            retry_base_delay: [
              type: :non_neg_integer,
              default: 1_000,
              doc: "Base retry delay (ms)"
            ],
            retry_max_delay: [
              type: :non_neg_integer,
              default: 30_000,
              doc: "Max retry delay (ms)"
            ],
            log_level: [
              type: {:in, [:debug, :info, :warning, :error, :none]},
              default: :info,
              doc: "HTTP log level"
            ]
          )

  @spec get() :: keyword()
  def get, do: NimbleOptions.validate!(Application.get_all_env(:xero), @schema)

  @spec get(atom()) :: term()
  def get(key), do: get()[key]

  @spec schema() :: NimbleOptions.t()
  def schema, do: @schema
end
