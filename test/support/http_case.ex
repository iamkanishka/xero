defmodule Xero.Test.HTTPCase do
  @moduledoc """
  ExUnit case template for tests that mock HTTP via Bypass.

  Usage:

      defmodule Xero.Accounting.InvoicesHTTPTest do
  @moduledoc false

        use Xero.Test.HTTPCase

        test "list/3 returns invoices", %{bypass: bypass, token: token, tenant_id: tid} do
          stub_xero(bypass, "GET", "/api.xro/2.0/Invoices", 200, %{
            "Invoices" => [Factory.invoice()]
          })

          assert {:ok, %{"Invoices" => [_]}} =
            Xero.Accounting.Invoices.list(token, tid, page: 1)
        end
      end
  """

  use ExUnit.CaseTemplate

  alias Xero.Test.Factory

  using do
    quote do
      import Xero.Test.HTTPCase
      alias Xero.Auth.Token
      alias Xero.Test.Factory
    end
  end

  setup do
    bypass = Bypass.open()

    Application.put_env(:xero,
      client_id: "test-client",
      client_secret: "test-secret",
      redirect_uri: "http://localhost/callback",
      base_url: "http://localhost:#{bypass.port}",
      identity_url: "http://localhost:#{bypass.port}",
      timeout: 5_000,
      connect_timeout: 2_000,
      pool_size: 2,
      pool_count: 1,
      log_level: :none
    )

    %{
      bypass: bypass,
      token: Factory.valid_token(),
      tenant_id: Factory.tenant_id()
    }
  end

  @doc """
  Stubs a Bypass endpoint to return a JSON response.

  ## Example

      stub_xero(bypass, "GET", "/api.xro/2.0/Invoices", 200, %{"Invoices" => []})
  """
  def stub_xero(bypass, method, path, status, body, extra_headers \\ []) do
    Bypass.stub(bypass, method, path, fn conn ->
      headers =
        [
          {"content-type", "application/json"},
          {"x-daylimit-remaining", "4999"},
          {"x-minlimit-remaining", "59"},
          {"x-correlation-id", "test-req-id"}
        ] ++ extra_headers

      conn =
        Enum.reduce(headers, conn, fn {k, v}, c ->
          Plug.Conn.put_resp_header(c, k, v)
        end)

      Plug.Conn.resp(conn, status, Jason.encode!(body))
    end)
  end

  @doc "Stubs a 429 rate-limit response with Retry-After header."
  def stub_rate_limited(bypass, method, path, retry_after \\ 30) do
    Bypass.stub(bypass, method, path, fn conn ->
      conn
      |> Plug.Conn.put_resp_header("retry-after", to_string(retry_after))
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.resp(429, ~s({"message": "Rate limit exceeded"}))
    end)
  end

  @doc "Stubs a 401 unauthorized response."
  def stub_unauthorized(bypass, method, path) do
    Bypass.stub(bypass, method, path, fn conn ->
      Plug.Conn.resp(conn, 401, ~s({"message": "AuthenticationUnsuccessful"}))
    end)
  end

  @doc "Stubs a 422 validation error response."
  def stub_validation_error(bypass, method, path, message \\ "Validation failed") do
    Bypass.stub(bypass, method, path, fn conn ->
      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.resp(422, Jason.encode!(%{"Message" => message, "ValidationErrors" => []}))
    end)
  end
end
