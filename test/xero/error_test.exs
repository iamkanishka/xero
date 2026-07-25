defmodule Xero.ErrorTest do
  @moduledoc false

  use ExUnit.Case, async: true
  alias Xero.Error

  describe "from_response/1" do
    test "401 → :unauthorized" do
      e = Error.from_response(%{status: 401, body: "", headers: []})
      assert e.type == :unauthorized
      assert e.status == 401
    end

    test "403 → :forbidden" do
      e = Error.from_response(%{status: 403, body: ~s({"Message":"Forbidden"}), headers: []})
      assert e.type == :forbidden
      assert e.status == 403
    end

    test "404 → :not_found" do
      e = Error.from_response(%{status: 404, body: "", headers: []})
      assert e.type == :not_found
    end

    test "422 → :unprocessable with message extraction" do
      body = Jason.encode!(%{"Message" => "Name is required"})
      e = Error.from_response(%{status: 422, body: body, headers: []})
      assert e.type == :unprocessable
      assert e.message == "Name is required"
      assert e.detail["Message"] == "Name is required"
    end

    test "429 → :rate_limited with retry_after from header" do
      e = Error.from_response(%{status: 429, body: "", headers: [{"retry-after", "45"}]})
      assert e.type == :rate_limited
      assert e.retry_after == 45
    end

    test "429 → :rate_limited defaults retry_after to 60 when header absent" do
      e = Error.from_response(%{status: 429, body: "", headers: []})
      assert e.retry_after == 60
    end

    test "500 → :server_error" do
      e = Error.from_response(%{status: 500, body: "Internal Server Error", headers: []})
      assert e.type == :server_error
      assert e.status == 500
    end

    test "503 → :server_error" do
      e = Error.from_response(%{status: 503, body: "", headers: []})
      assert e.type == :server_error
    end

    test "extracts x-correlation-id as request_id" do
      e =
        Error.from_response(%{status: 404, body: "", headers: [{"x-correlation-id", "req-abc"}]})

      assert e.request_id == "req-abc"
    end
  end

  describe "network_error/1" do
    test "wraps reason with :network_error type" do
      e = Error.network_error(:timeout)
      assert e.type == :network_error
      assert e.raw == :timeout
      assert e.message =~ "timeout"
    end
  end

  describe "config_error/1" do
    test "creates a config error" do
      e = Error.config_error("missing client_id")
      assert e.type == :config_error
      assert e.message == "missing client_id"
    end
  end

  describe "Exception behaviour" do
    test "message/1 includes type and status" do
      e = %Error{type: :rate_limited, status: 429, message: "Too many requests"}
      msg = Exception.message(e)
      assert msg =~ "rate_limited"
      assert msg =~ "429"
      assert msg =~ "Too many requests"
    end

    test "message/1 works without status" do
      e = %Error{type: :network_error, message: "connection refused"}
      msg = Exception.message(e)
      assert msg =~ "network_error"
      assert msg =~ "connection refused"
    end
  end
end
