defmodule Xero.Auth.TokenStoreTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias Xero.Auth.Token
  alias Xero.Auth.TokenStore

  setup do
    if :ets.whereis(:xero_token_store) != :undefined do
      :ets.delete_all_objects(:xero_token_store)
    end

    :ok
  end

  defp valid_token do
    %Token{
      access_token: "access-#{System.unique_integer([:positive])}",
      refresh_token: "refresh-#{System.unique_integer([:positive])}",
      expires_at: DateTime.add(DateTime.utc_now(), 3_600, :second),
      token_type: "Bearer",
      scopes: ["accounting.transactions"]
    }
  end

  describe "put/3 and get/2" do
    test "stores and retrieves a token" do
      uid = "user-#{System.unique_integer([:positive])}"
      tid = "tenant-#{System.unique_integer([:positive])}"
      token = valid_token()

      assert :ok = TokenStore.put(uid, tid, token)
      assert {:ok, ^token} = TokenStore.get(uid, tid)
    end

    test "returns :not_found for unknown user/tenant" do
      assert {:error, :not_found} = TokenStore.get("no-such-user", "no-such-tenant")
    end

    test "overwriting updates the stored token" do
      uid = "user-#{System.unique_integer([:positive])}"
      tid = "tenant-#{System.unique_integer([:positive])}"
      old = valid_token()
      new = %{old | access_token: "new-access-token"}

      TokenStore.put(uid, tid, old)
      TokenStore.put(uid, tid, new)

      {:ok, stored} = TokenStore.get(uid, tid)
      assert stored.access_token == "new-access-token"
    end

    test "multiple user/tenant pairs stored independently" do
      pairs =
        for i <- 1..3 do
          uid = "user-#{i}-#{System.unique_integer([:positive])}"
          tid = "tenant-#{i}-#{System.unique_integer([:positive])}"
          token = %{valid_token() | access_token: "token-#{i}"}
          TokenStore.put(uid, tid, token)
          {uid, tid, token}
        end

      Enum.each(pairs, fn {uid, tid, expected} ->
        {:ok, stored} = TokenStore.get(uid, tid)
        assert stored.access_token == expected.access_token
      end)
    end
  end

  describe "delete/2" do
    test "removes a stored token" do
      uid = "user-#{System.unique_integer([:positive])}"
      tid = "tenant-#{System.unique_integer([:positive])}"
      token = valid_token()

      TokenStore.put(uid, tid, token)
      assert {:ok, _} = TokenStore.get(uid, tid)

      assert :ok = TokenStore.delete(uid, tid)
      assert {:error, :not_found} = TokenStore.get(uid, tid)
    end

    test "deleting non-existent key does not raise" do
      assert :ok = TokenStore.delete("ghost-user", "ghost-tenant")
    end
  end

  describe "list_keys/0" do
    test "returns all stored user/tenant pairs" do
      uid1 = "user-list-#{System.unique_integer([:positive])}"
      uid2 = "user-list-#{System.unique_integer([:positive])}"
      tid = "tenant-list-#{System.unique_integer([:positive])}"

      TokenStore.put(uid1, tid, valid_token())
      TokenStore.put(uid2, tid, valid_token())

      keys = TokenStore.list_keys()
      assert {uid1, tid} in keys
      assert {uid2, tid} in keys
    end
  end
end
