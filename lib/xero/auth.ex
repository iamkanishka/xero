defmodule Xero.Auth do
  @moduledoc """
  OAuth 2.0 authentication for all Xero APIs.

  Xero uses the **Authorization Code Flow** for server-side apps.
  Access tokens expire after **30 minutes**; use `refresh_token/1` to renew.
  The `offline_access` scope is required to obtain refresh tokens.

  ## Flow

      # 1. Generate auth URL
      {:ok, url, state} = Xero.Auth.authorize_url()
      # store state in session, redirect user to url

      # 2. Exchange code for tokens
      {:ok, tokens} = Xero.Auth.fetch_token(code)

      # 3. List connected organisations
      {:ok, connections} = Xero.Auth.connections(tokens)
      tenant_id = hd(connections).tenant_id

      # 4. Refresh when expired
      {:ok, new_tokens} = Xero.Auth.refresh_token(tokens.refresh_token)

      # 5. Revoke on disconnect
      :ok = Xero.Auth.revoke_token(tokens.refresh_token)
  """

  alias Xero.Auth.Token
  alias Xero.Config
  alias Xero.Error
  alias Xero.HTTP.Client

  @authorize_url "https://login.xero.com/identity/connect/authorize"
  @token_url "https://identity.xero.com/connect/token"
  @revoke_url "https://identity.xero.com/connect/revocation"
  @connections_url "https://api.xero.com/connections"

  @doc """
  Generates the Xero OAuth2 authorization URL with a random CSRF state.
  Returns `{:ok, url, state}`. Store `state` in session and validate on callback.

  ## Options
  - `:scopes` — override configured scopes
  - `:state`  — supply a custom state string (default: random 32 bytes)
  """
  @spec authorize_url(keyword()) :: {:ok, String.t(), String.t()} | {:error, Error.t()}
  def authorize_url(opts \\ []) do
    config = Config.get()
    state = opts[:state] || generate_state()
    scopes = opts[:scopes] || config[:scopes]

    params = %{
      response_type: "code",
      client_id: config[:client_id],
      redirect_uri: config[:redirect_uri],
      scope: Enum.join(scopes, " "),
      state: state
    }

    {:ok, @authorize_url <> "?" <> URI.encode_query(params), state}
  end

  @doc "Exchanges an authorization code for access + refresh tokens."
  @spec fetch_token(String.t()) :: {:ok, Token.t()} | {:error, Error.t()}
  def fetch_token(code) do
    config = Config.get()

    post_token(
      %{grant_type: "authorization_code", code: code, redirect_uri: config[:redirect_uri]},
      config
    )
  end

  @doc """
  Refreshes an expired access token.
  Requires the `offline_access` scope to have been requested originally.
  """
  @spec refresh_token(String.t()) :: {:ok, Token.t()} | {:error, Error.t()}
  def refresh_token(refresh_token_value) do
    result =
      post_token(%{grant_type: "refresh_token", refresh_token: refresh_token_value}, Config.get())

    case result do
      {:ok, _} = ok ->
        :telemetry.execute([:xero, :auth, :token_refreshed], %{}, %{})
        ok

      {:error, _} = err ->
        :telemetry.execute([:xero, :auth, :token_refresh_failed], %{}, %{})
        err
    end
  end

  @doc "Revokes a refresh token, disconnecting the user's Xero access."
  @spec revoke_token(String.t()) :: :ok | {:error, Error.t()}
  def revoke_token(refresh_token_value) do
    config = Config.get()
    auth = basic_auth(config)

    case Client.post_form(@revoke_url, %{token: refresh_token_value}, [{"authorization", auth}],
           skip_tenant: true
         ) do
      {:ok, %{status: 200}} -> :ok
      {:ok, resp} -> {:error, Error.from_response(resp)}
      {:error, _} = err -> err
    end
  end

  @doc """
  Returns the list of Xero organisations the authenticated user has connected.
  Each connection map contains `:tenant_id`, `:tenant_name`, `:tenant_type`.
  """
  @spec connections(Token.t()) :: {:ok, list(map())} | {:error, Error.t()}
  def connections(%Token{} = token) do
    case Client.get(@connections_url, token, [], skip_tenant: true) do
      {:ok, %{status: 200, body: body}} ->
        conns = Enum.map(Jason.decode!(body), &parse_connection/1)
        {:ok, conns}

      {:ok, resp} ->
        {:error, Error.from_response(resp)}

      {:error, _} = err ->
        err
    end
  end

  @doc "Returns `true` if the token is expired or expiring within 60 seconds."
  @spec token_expired?(Token.t()) :: boolean()
  def token_expired?(%Token{expires_at: exp}),
    do: DateTime.compare(DateTime.utc_now(), DateTime.add(exp, -60, :second)) != :lt

  @doc """
  Returns a valid token, refreshing automatically if expired.

      {:ok, valid} = Xero.Auth.ensure_valid_token(tokens)
  """
  @spec ensure_valid_token(Token.t()) :: {:ok, Token.t()} | {:error, Error.t()}
  def ensure_valid_token(%Token{} = token) do
    if token_expired?(token) do
      refresh_token(token.refresh_token)
    else
      {:ok, token}
    end
  end

  # --- Private ---

  @spec post_token(map(), keyword()) :: {:ok, Token.t()} | {:error, Error.t()}
  defp post_token(body, config) do
    auth = basic_auth(config)

    case Client.post_form(@token_url, body, [{"authorization", auth}], skip_tenant: true) do
      {:ok, %{status: 200, body: raw}} ->
        {:ok, Token.from_response(Jason.decode!(raw))}

      {:ok, resp} ->
        {:error,
         %Error{
           type: :oauth_error,
           status: resp.status,
           raw: resp.body,
           message: extract_oauth_error(resp.body)
         }}

      {:error, _} = err ->
        err
    end
  end

  defp basic_auth(config),
    do: "Basic " <> Base.encode64("#{config[:client_id]}:#{config[:client_secret]}")

  defp generate_state,
    do: Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)

  defp parse_connection(c) do
    %{
      id: c["id"],
      tenant_id: c["tenantId"],
      tenant_type: c["tenantType"],
      tenant_name: c["tenantName"],
      created_date_utc: c["createdDateUtc"],
      updated_date_utc: c["updatedDateUtc"]
    }
  end

  defp extract_oauth_error(body) do
    case Jason.decode(body) do
      {:ok, %{"error_description" => d}} -> d
      {:ok, %{"error" => e}} -> e
      _ -> "OAuth error"
    end
  end
end
