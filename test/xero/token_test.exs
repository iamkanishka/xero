defmodule Xero.Auth.TokenTest do
  @moduledoc false

  use ExUnit.Case, async: true
  alias Xero.Auth.Token

  describe "from_response/1" do
    test "parses complete token response" do
      resp = %{
        "access_token" => "abc123",
        "refresh_token" => "refresh456",
        "expires_in" => 1_800,
        "token_type" => "Bearer",
        "scope" => "openid accounting.transactions",
        "id_token" => "eyJ.test.token"
      }

      token = Token.from_response(resp)

      assert token.access_token == "abc123"
      assert token.refresh_token == "refresh456"
      assert token.token_type == "Bearer"
      assert token.id_token == "eyJ.test.token"
      assert token.scopes == ["openid", "accounting.transactions"]
      assert DateTime.compare(token.expires_at, DateTime.utc_now()) == :gt
    end

    test "expires_at is approximately now + expires_in seconds" do
      resp = %{"access_token" => "t", "expires_in" => 1_800}
      token = Token.from_response(resp)
      diff = DateTime.diff(token.expires_at, DateTime.utc_now())
      assert diff > 1_790 && diff <= 1_801
    end

    test "defaults expires_in to 1_800 when absent" do
      resp = %{"access_token" => "t"}
      token = Token.from_response(resp)
      diff = DateTime.diff(token.expires_at, DateTime.utc_now())
      assert diff > 1_790
    end

    test "defaults token_type to Bearer when absent" do
      resp = %{"access_token" => "t", "expires_in" => 1_800}
      token = Token.from_response(resp)
      assert token.token_type == "Bearer"
    end

    test "handles nil scope → empty scopes list" do
      resp = %{"access_token" => "t", "expires_in" => 1_800}
      token = Token.from_response(resp)
      assert token.scopes == []
    end

    test "handles list scope" do
      resp = %{"access_token" => "t", "expires_in" => 1_800, "scope" => ["a", "b"]}
      token = Token.from_response(resp)
      assert token.scopes == ["a", "b"]
    end

    test "optional fields are nil when absent" do
      resp = %{"access_token" => "t", "expires_in" => 1_800}
      token = Token.from_response(resp)
      assert is_nil(token.refresh_token)
      assert is_nil(token.id_token)
    end
  end

  describe "auth_header/1" do
    test "returns correct Bearer authorization header" do
      token = %Token{access_token: "mytoken", token_type: "Bearer"}
      assert Token.auth_header(token) == {"authorization", "Bearer mytoken"}
    end

    test "uses the actual token_type field" do
      token = %Token{access_token: "mytoken", token_type: "MAC"}
      {_key, value} = Token.auth_header(token)
      assert value =~ "MAC"
    end
  end
end
