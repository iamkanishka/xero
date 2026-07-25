defmodule Xero.AuthTest do
  @moduledoc false

  use ExUnit.Case, async: true
  alias Xero.Auth
  alias Xero.Auth.Token

  # Seed test config before each test
  setup do
    Application.put_env(:xero,
      client_id: "test-client-id",
      client_secret: "test-client-secret",
      redirect_uri: "https://app.test/callback",
      scopes: ~w(openid profile email offline_access accounting.transactions)
    )

    :ok
  end

  describe "authorize_url/1" do
    test "returns a tuple of {:ok, url, state}" do
      assert {:ok, url, state} = Auth.authorize_url()
      assert is_binary(url)
      assert is_binary(state)
    end

    test "URL contains required OAuth parameters" do
      {:ok, url, _state} = Auth.authorize_url()
      uri = URI.parse(url)
      params = URI.decode_query(uri.query)

      assert params["response_type"] == "code"
      assert params["client_id"] == "test-client-id"
      assert params["redirect_uri"] == "https://app.test/callback"
      assert params["scope"] =~ "openid"
      assert params["state"] != nil
    end

    test "state is a random non-empty string of sufficient length" do
      {:ok, _url, state} = Auth.authorize_url()
      assert String.length(state) >= 40
    end

    test "two calls generate different states" do
      {:ok, _url1, state1} = Auth.authorize_url()
      {:ok, _url2, state2} = Auth.authorize_url()
      refute state1 == state2
    end

    test "accepts custom state" do
      {:ok, url, state} = Auth.authorize_url(state: "my-custom-state")
      assert state == "my-custom-state"
      assert url =~ "my-custom-state"
    end

    test "accepts custom scopes" do
      {:ok, url, _state} = Auth.authorize_url(scopes: ["openid", "projects"])
      uri = URI.parse(url)
      params = URI.decode_query(uri.query)
      assert params["scope"] == "openid projects"
    end
  end

  describe "token_expired?/1" do
    test "returns true for token with past expiry" do
      token = %Token{expires_at: DateTime.add(DateTime.utc_now(), -300, :second)}
      assert Auth.token_expired?(token) == true
    end

    test "returns true for token expiring within 60 seconds (safety buffer)" do
      token = %Token{expires_at: DateTime.add(DateTime.utc_now(), 30, :second)}
      assert Auth.token_expired?(token) == true
    end

    test "returns false for token with plenty of time remaining" do
      token = %Token{expires_at: DateTime.add(DateTime.utc_now(), 1_800, :second)}
      assert Auth.token_expired?(token) == false
    end

    test "returns false for token expiring in exactly 61 seconds" do
      token = %Token{expires_at: DateTime.add(DateTime.utc_now(), 61, :second)}
      assert Auth.token_expired?(token) == false
    end
  end

  describe "ensure_valid_token/1" do
    test "returns the token unchanged when still valid" do
      token = %Token{
        access_token: "valid-token",
        refresh_token: "refresh",
        expires_at: DateTime.add(DateTime.utc_now(), 1_800, :second)
      }

      assert {:ok, ^token} = Auth.ensure_valid_token(token)
    end
  end
end
