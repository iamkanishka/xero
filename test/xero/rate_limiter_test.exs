defmodule Xero.HTTP.RateLimiterTest do
  @moduledoc false

  # ETS is global, don't run async
  use ExUnit.Case, async: false

  alias Xero.HTTP.RateLimiter

  setup do
    # Clear all rate limit state before each test
    if :ets.whereis(:xero_rate_limits) != :undefined do
      :ets.delete_all_objects(:xero_rate_limits)
    end

    :ok
  end

  describe "track_request/1" do
    test "allows first request for a new tenant" do
      assert RateLimiter.track_request("tenant-new-#{unique()}") == :ok
    end

    test "increments day_used and min_used counters" do
      tenant = "tenant-#{unique()}"
      RateLimiter.track_request(tenant)
      state = RateLimiter.get_state(tenant)
      assert state.day_used == 1
      assert state.min_used == 1
    end

    test "allows multiple requests within limits" do
      tenant = "tenant-#{unique()}"
      for _ <- 1..10, do: assert(RateLimiter.track_request(tenant) == :ok)
      assert RateLimiter.get_state(tenant).day_used == 10
    end

    test "different tenants are tracked independently" do
      t1 = "tenant-#{unique()}"
      t2 = "tenant-#{unique()}"
      for _ <- 1..5, do: RateLimiter.track_request(t1)
      for _ <- 1..3, do: RateLimiter.track_request(t2)
      assert RateLimiter.get_state(t1).day_used == 5
      assert RateLimiter.get_state(t2).day_used == 3
    end
  end

  describe "get_state/1" do
    test "returns default state for unknown tenant" do
      state = RateLimiter.get_state("completely-unknown-tenant-#{unique()}")
      assert state.day_used == 0
      assert state.min_used == 0
      assert state.day_remaining == 5_000
      assert state.min_remaining == 60
    end

    test "returns current state after tracking requests" do
      tenant = "tenant-#{unique()}"
      RateLimiter.track_request(tenant)
      RateLimiter.track_request(tenant)
      state = RateLimiter.get_state(tenant)
      assert state.day_used == 2
    end
  end

  describe "update_from_headers/2" do
    test "updates remaining counters from response headers" do
      tenant = "tenant-#{unique()}"
      headers = [{"x-daylimit-remaining", "4500"}, {"x-minlimit-remaining", "45"}]
      RateLimiter.update_from_headers(tenant, headers)
      # Allow GenServer cast to process
      :timer.sleep(10)
      state = RateLimiter.get_state(tenant)
      assert state.day_remaining == 4_500
      assert state.min_remaining == 45
    end

    test "ignores missing headers gracefully" do
      tenant = "tenant-#{unique()}"
      assert RateLimiter.update_from_headers(tenant, []) == :ok
    end
  end

  defp unique, do: System.unique_integer([:positive])
end
