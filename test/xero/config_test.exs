defmodule Xero.ConfigTest do
  @moduledoc false

  use ExUnit.Case, async: false

  setup do
    # Store original env to restore after test
    original = Application.get_all_env(:xero)

    on_exit(fn ->
      Enum.each(original, fn {k, v} -> Application.put_env(:xero, k, v) end)
    end)

    :ok
  end

  describe "get/0" do
    test "returns validated config with defaults applied" do
      Application.put_env(:xero, :client_id, "my-client")
      Application.put_env(:xero, :client_secret, "my-secret")
      Application.put_env(:xero, :redirect_uri, "https://example.com/callback")

      config = Xero.Config.get()

      assert config[:client_id] == "my-client"
      assert config[:client_secret] == "my-secret"
      assert config[:redirect_uri] == "https://example.com/callback"
      assert config[:timeout] == 30_000
      assert config[:connect_timeout] == 10_000
      assert config[:pool_size] == 10
      assert config[:pool_count] == 4
      assert config[:max_retries] == 3
      assert config[:log_level] == :info
    end

    test "uses configured scopes when provided" do
      Application.put_env(:xero, :client_id, "c")
      Application.put_env(:xero, :client_secret, "s")
      Application.put_env(:xero, :redirect_uri, "https://example.com/cb")
      Application.put_env(:xero, :scopes, ["openid", "assets"])

      config = Xero.Config.get()
      assert config[:scopes] == ["openid", "assets"]
    end

    test "raises NimbleOptions.ValidationError when client_id is missing" do
      Application.delete_env(:xero, :client_id)
      Application.put_env(:xero, :client_secret, "s")
      Application.put_env(:xero, :redirect_uri, "https://example.com/cb")

      assert_raise NimbleOptions.ValidationError, ~r/client_id/, fn ->
        Xero.Config.get()
      end
    end

    test "raises when log_level is invalid" do
      Application.put_env(:xero, :client_id, "c")
      Application.put_env(:xero, :client_secret, "s")
      Application.put_env(:xero, :redirect_uri, "https://example.com/cb")
      Application.put_env(:xero, :log_level, :verbose)

      assert_raise NimbleOptions.ValidationError, fn ->
        Xero.Config.get()
      end
    end
  end

  describe "get/1" do
    test "retrieves a single config key" do
      Application.put_env(:xero, :client_id, "single-key-test")
      Application.put_env(:xero, :client_secret, "s")
      Application.put_env(:xero, :redirect_uri, "https://example.com/cb")

      assert Xero.Config.get(:client_id) == "single-key-test"
    end
  end

  describe "schema/0" do
    test "returns a NimbleOptions struct" do
      schema = Xero.Config.schema()
      assert is_struct(schema, NimbleOptions)
    end
  end
end
