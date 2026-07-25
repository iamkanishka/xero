defmodule Xero.HTTP.Client do
  @moduledoc """
  Core HTTP client for all Xero API requests.

  Handles:
  - Authenticated requests with Bearer token injection
  - Automatic token refresh on 401 responses
  - Rate limit header tracking and `Retry-After` respect
  - Telemetry emission for every request
  - JSON encode/decode (transparent)
  - Request ID injection (`x-correlation-id`)
  - `If-Modified-Since` header injection for incremental sync
  - Multi-part form posting for OAuth token endpoints
  """

  require Logger

  alias Xero.{Auth, Config, Error}
  alias Xero.Auth.Token
  alias Xero.HTTP.RateLimiter

  @base_urls %{
    accounting: "https://api.xero.com/api.xro/2.0",
    assets: "https://api.xero.com/assets.xro/1.0",
    files: "https://api.xero.com/files.xro/1.0",
    finance: "https://api.xero.com/finance.xro/1.0",
    projects: "https://api.xero.com/projects.xro/2.0",
    payroll_au: "https://api.xero.com/payroll.xro/1.0",
    payroll_nz: "https://api.xero.com/payrollnz.xro/1.0",
    payroll_uk: "https://api.xero.com/payroll.xro/2.0",
    bankfeeds: "https://api.xero.com/bankfeeds.xro/1.0",
    appstore: "https://api.xero.com/appstore/2.0",
    einvoicing: "https://api.xero.com/einvoicing",
    practice_manager: "https://api.xero.com/practicemanager/3.1"
  }

  @doc false
  @spec base_url(atom()) :: String.t()
  def base_url(api), do: Map.fetch!(@base_urls, api)

  @type opts :: [
          tenant_id: String.t() | nil,
          skip_tenant: boolean(),
          accept: String.t(),
          if_modified_since: DateTime.t() | String.t() | nil,
          params: map() | keyword()
        ]

  @typedoc "Normalised HTTP response shape used internally, regardless of adapter (Req/Finch)."
  @type response :: %{status: pos_integer(), body: term(), headers: [{String.t(), String.t()}]}

  @typedoc "Raw `{:ok, adapter_response} | {:error, term()}` as returned by the underlying Req call."
  @type raw_result :: {:ok, map()} | {:error, term()}

  @type method :: :get | :post | :put | :delete
  @type result :: {:ok, response()} | {:error, Error.t()}

  @doc "Authenticated GET request."
  @spec get(String.t(), Token.t(), list(), opts()) :: result()
  def get(url, token, extra_headers \\ [], opts \\ []) do
    request(:get, url, nil, token, extra_headers, opts)
  end

  @doc "Authenticated POST request with JSON body."
  @spec post(String.t(), term(), Token.t(), list(), opts()) :: result()
  def post(url, body, token, extra_headers \\ [], opts \\ []) do
    request(:post, url, body, token, extra_headers, opts)
  end

  @doc "Authenticated PUT request with JSON body."
  @spec put(String.t(), term(), Token.t(), list(), opts()) :: result()
  def put(url, body, token, extra_headers \\ [], opts \\ []) do
    request(:put, url, body, token, extra_headers, opts)
  end

  @doc "Authenticated DELETE request."
  @spec delete(String.t(), Token.t(), list(), opts()) :: result()
  def delete(url, token, extra_headers \\ [], opts \\ []) do
    request(:delete, url, nil, token, extra_headers, opts)
  end

  @doc "Form-encoded POST for OAuth token endpoints (no auth token required)."
  @spec post_form(String.t(), map(), list(), opts()) :: result()
  def post_form(url, body, extra_headers \\ [], _opts \\ []) do
    config = Config.get()

    headers =
      [
        {"content-type", "application/x-www-form-urlencoded"},
        {"accept", "application/json"},
        {"user-agent", user_agent()}
      ] ++ extra_headers

    t0 = System.monotonic_time()

    raw =
      Req.post(url,
        body: URI.encode_query(body),
        headers: headers,
        receive_timeout: config[:timeout],
        connect_options: [timeout: config[:connect_timeout]],
        finch: Xero.Finch
      )

    emit_telemetry(:post, url, nil, raw, t0)
    normalise(raw)
  end

  # ─── Private ─────────────────────────────────────────────────────────────────

  # Explicit @spec is required here: request/6 and handle/7 are mutually
  # recursive (handle/7's 429-clause calls back into request/6), which makes
  # them a single Dialyzer SCC. Without a declared contract, Dialyzer must
  # infer the return type purely from the recursive body, and — because the
  # `with` below has no `else` — the {:error, ...} exit resolves to a small
  # concrete type long before the success exit (which depends on the
  # not-yet-resolved recursive call) is folded in. That lets Dialyzer's
  # widening collapse the whole SCC to {:error, Error.t()} only, which then
  # cascades into every {:ok, ...} match across the SDK being flagged as
  # unreachable. Declaring the spec makes Dialyzer trust (and check against)
  # the contract instead of deriving it from the cycle.
  @spec request(method(), String.t(), term(), Token.t(), list(), opts()) :: result()
  defp request(method, url, body, %Token{} = token, extra_headers, opts) do
    case Auth.ensure_valid_token(token) do
      {:ok, valid_token} ->
        config = Config.get()
        tenant_id = opts[:tenant_id]
        headers = build_headers(valid_token, tenant_id, extra_headers, opts)
        params = clean_params(opts[:params] || [])
        t0 = System.monotonic_time()

        if tenant_id && !opts[:skip_tenant],
          do: RateLimiter.track_request(tenant_id)

        req_opts = [
          headers: headers,
          params: params,
          receive_timeout: config[:timeout],
          connect_options: [timeout: config[:connect_timeout]],
          finch: Xero.Finch
        ]

        raw =
          case method do
            :get -> Req.get(url, req_opts)
            :post -> Req.post(url, Keyword.put(req_opts, :json, body))
            :put -> Req.put(url, Keyword.put(req_opts, :json, body))
            :delete -> Req.delete(url, req_opts)
          end

        emit_telemetry(method, url, tenant_id, raw, t0)
        handle(raw, method, url, body, valid_token, extra_headers, opts)

      {:error, _} = err ->
        err
    end
  end

  # ─── Response Handling ────────────────────────────────────────────────────────

  @spec handle(raw_result(), method(), String.t(), term(), Token.t(), list(), opts()) :: result()
  defp handle({:ok, %{status: s} = resp}, _m, _u, _b, _t, _h, _o)
       when s in 200..299 do
    update_rate_limits(resp)
    {:ok, normalise_resp(resp)}
  end

  defp handle({:ok, %{status: 429} = resp}, method, url, body, token, headers, opts) do
    secs = parse_retry_after(resp)
    Logger.warning("[Xero] Rate limited — waiting #{secs}s before retry")
    Process.sleep(secs * 1_000)
    request(method, url, body, token, headers, opts)
  end

  defp handle({:ok, resp}, _m, _u, _b, _t, _h, _o) do
    {:error, Error.from_response(normalise_resp(resp))}
  end

  defp handle({:error, reason}, _m, _u, _b, _t, _h, _o) do
    {:error, Error.network_error(reason)}
  end

  @spec normalise(raw_result()) :: result()
  defp normalise({:ok, resp}), do: {:ok, normalise_resp(resp)}
  defp normalise({:error, r}), do: {:error, Error.network_error(r)}

  @spec normalise_resp(map()) :: response()
  defp normalise_resp(resp) do
    %{
      status: resp.status,
      body: format_body(resp.body),
      headers: normalise_headers(resp.headers)
    }
  end

  # ─── Headers ─────────────────────────────────────────────────────────────────

  defp build_headers(%Token{} = token, tenant_id, extra, opts) do
    base = [
      Token.auth_header(token),
      {"accept", opts[:accept] || "application/json"},
      {"content-type", "application/json"},
      {"user-agent", user_agent()},
      {"x-correlation-id", request_id()}
    ]

    tenant_h =
      if tenant_id && !opts[:skip_tenant],
        do: [{"xero-tenant-id", tenant_id}],
        else: []

    modified_h =
      case opts[:if_modified_since] do
        nil -> []
        %DateTime{} = dt -> [{"if-modified-since", format_http_date(dt)}]
        s when is_binary(s) -> [{"if-modified-since", s}]
      end

    base ++ tenant_h ++ modified_h ++ extra
  end

  # ─── Telemetry & Rate Limits ─────────────────────────────────────────────────

  @spec update_rate_limits(Req.Response.t()) :: :ok
  defp update_rate_limits(%{headers: headers}) do
    day = get_header(headers, "x-daylimit-remaining")
    min = get_header(headers, "x-minlimit-remaining")
    app = get_header(headers, "x-appminlimit-remaining")

    if day || min do
      :telemetry.execute(
        [:xero, :rate_limit, :remaining],
        %{
          day_remaining: parse_int(day),
          min_remaining: parse_int(min),
          app_min_remaining: parse_int(app)
        },
        %{}
      )
    end

    :ok
  end

  defp emit_telemetry(method, url, tenant_id, result, t0) do
    status =
      case result do
        {:ok, %{status: s}} -> s
        _ -> 0
      end

    :telemetry.execute(
      [:xero, :http, :request],
      %{duration: System.monotonic_time() - t0},
      %{method: method, url: url, status: status, tenant_id: tenant_id}
    )
  end

  @spec parse_retry_after(map()) :: pos_integer()
  defp parse_retry_after(%{headers: headers}) do
    (get_header(headers, "retry-after") || "60") |> String.to_integer()
  end

  # ─── Helpers ─────────────────────────────────────────────────────────────────

  @spec normalise_headers(map()) :: [{String.t(), String.t()}]
  defp normalise_headers(h) do
    Enum.map(h, fn
      {k, [v | _]} -> {to_string(k), to_string(v)}
      {k, v} -> {to_string(k), to_string(v)}
    end)
  end

  # Req.Response's :headers field is a map of `%{binary() => [binary()]}`
  # (HTTP allows repeated headers, so each value is a list) — NOT a keyword
  # list. List.keyfind only works on lists, so calling it on the real map
  # shape always raised at runtime; Dialyzer correctly flagged get_header/2
  # as having no local return once it saw the actual Req.Response type.
  @spec get_header(map(), String.t()) :: String.t() | nil
  defp get_header(headers, name) do
    case Map.get(headers, name) do
      [v | _] -> v
      v when is_binary(v) -> v
      _ -> nil
    end
  end

  defp format_body(b) when is_binary(b), do: b
  defp format_body(b), do: Jason.encode!(b)

  @spec parse_int(nil | String.t()) :: nil | integer()
  defp parse_int(nil), do: nil
  defp parse_int(s), do: String.to_integer(s)

  defp clean_params(p) do
    p
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp request_id do
    Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)
  end

  defp user_agent do
    "xero-elixir/#{Xero.version()} (Elixir/#{System.version()})"
  end

  defp format_http_date(%DateTime{} = dt) do
    Calendar.strftime(dt, "%a, %d %b %Y %H:%M:%S GMT")
  end
end
