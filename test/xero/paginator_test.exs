defmodule Xero.PaginatorTest do
  @moduledoc false

  use ExUnit.Case, async: true
  alias Xero.{Error, Paginator}

  @page_size 100

  describe "stream/2" do
    test "returns empty stream when first page is empty" do
      fetch = fn [page: _] -> {:ok, []} end
      assert Enum.to_list(Paginator.stream(fetch)) == []
    end

    test "returns all items from a single partial page" do
      items = Enum.map(1..5, &%{"id" => &1})
      fetch = fn [page: _] -> {:ok, items} end
      assert Enum.to_list(Paginator.stream(fetch)) == items
    end

    test "auto-paginates when page is full (100 items)" do
      page1 = Enum.map(1..@page_size, &%{"id" => &1})
      page2 = Enum.map(101..105, &%{"id" => &1})

      fetch = fn
        [page: 1] -> {:ok, page1}
        [page: 2] -> {:ok, page2}
      end

      result = Enum.to_list(Paginator.stream(fetch))
      assert length(result) == 105
      assert List.first(result)["id"] == 1
      assert List.last(result)["id"] == 105
    end

    test "handles three full pages then a partial page" do
      make_page = fn offset -> Enum.map((offset + 1)..(offset + @page_size), &%{"id" => &1}) end

      fetch = fn
        [page: 1] -> {:ok, make_page.(0)}
        [page: 2] -> {:ok, make_page.(@page_size)}
        [page: 3] -> {:ok, make_page.(@page_size * 2)}
        [page: 4] -> {:ok, [%{"id" => 301}]}
      end

      result = Enum.to_list(Paginator.stream(fetch))
      assert length(result) == 301
    end

    test "halts on error (does not crash)" do
      fetch = fn
        [page: 1] -> {:ok, Enum.map(1..@page_size, &%{"id" => &1})}
        [page: 2] -> {:error, %Error{type: :server_error, message: "boom"}}
      end

      # Stream stops after error, returns only page 1
      result = Enum.to_list(Paginator.stream(fetch))
      assert length(result) == @page_size
    end

    test "is lazy — does not call fetch_fn until enumerated" do
      calls = :ets.new(:paginator_test_calls, [:set, :public])
      :ets.insert(calls, {:count, 0})

      fetch = fn [page: _] ->
        [{:count, n}] = :ets.lookup(calls, :count)
        :ets.insert(calls, {:count, n + 1})
        {:ok, []}
      end

      _stream = Paginator.stream(fetch)
      [{:count, n}] = :ets.lookup(calls, :count)
      assert n == 0, "fetch_fn should not be called until stream is enumerated"

      :ets.delete(calls)
    end

    test "Stream.take/2 only fetches necessary pages" do
      call_count = :counters.new(1, [])

      fetch = fn [page: _] ->
        :counters.add(call_count, 1, 1)
        {:ok, Enum.map(1..@page_size, &%{"id" => &1})}
      end

      fetch
      |> Paginator.stream()
      |> Stream.take(50)
      |> Enum.to_list()

      assert :counters.get(call_count, 1) == 1
    end

    test "respects :start_page option" do
      pages_fetched = :ets.new(:pages_fetched, [:set, :public])

      fetch = fn [page: p] ->
        :ets.insert(pages_fetched, {p, true})
        {:ok, [%{"id" => p}]}
      end

      Enum.to_list(Paginator.stream(fetch, start_page: 3))

      assert :ets.lookup(pages_fetched, 1) == []
      assert :ets.lookup(pages_fetched, 2) == []
      assert :ets.lookup(pages_fetched, 3) != []

      :ets.delete(pages_fetched)
    end
  end

  describe "fetch_all/2" do
    test "returns all items as a flat list" do
      page1 = Enum.map(1..@page_size, &%{"id" => &1})
      page2 = [%{"id" => 101}]

      fetch = fn
        [page: 1] -> {:ok, page1}
        [page: 2] -> {:ok, page2}
      end

      assert {:ok, result} = Paginator.fetch_all(fetch)
      assert length(result) == 101
    end

    test "extracts items by :key option when response is a map" do
      response1 = %{"Contacts" => Enum.map(1..@page_size, &%{"id" => &1})}
      response2 = %{"Contacts" => [%{"id" => 101}]}

      fetch = fn
        [page: 1] -> {:ok, response1}
        [page: 2] -> {:ok, response2}
      end

      assert {:ok, contacts} = Paginator.fetch_all(fetch, key: "Contacts")
      assert length(contacts) == 101
    end

    test "returns {:error, _} when any page fails" do
      error = %Error{type: :server_error, message: "Xero down"}

      fetch = fn
        [page: 1] -> {:error, error}
      end

      assert {:error, ^error} = Paginator.fetch_all(fetch)
    end

    test "handles empty first page" do
      fetch = fn [page: _] -> {:ok, []} end
      assert {:ok, []} = Paginator.fetch_all(fetch)
    end
  end

  describe "fetch_page/2" do
    test "fetches page 1 by default" do
      fetch = fn [page: p] -> {:ok, [%{"page" => p}]} end
      assert {:ok, [%{"page" => 1}]} = Paginator.fetch_page(fetch)
    end

    test "fetches the specified page" do
      fetch = fn [page: p] -> {:ok, [%{"page" => p}]} end
      assert {:ok, [%{"page" => 5}]} = Paginator.fetch_page(fetch, page: 5)
    end
  end

  describe "page_size/0" do
    test "always returns 100 (Xero fixed page size)" do
      assert Paginator.page_size() == 100
    end
  end
end
