defmodule Xero.Paginator do
  @moduledoc """
  Pagination helpers for Xero API endpoints.

  Xero returns **100 items per page** (fixed). Endpoints supporting pagination:
  Invoices, Contacts, Bank Transactions, Manual Journals, Purchase Orders, Payments.

  ## Usage

      # Lazy stream (recommended — memory-efficient)
      Xero.Accounting.Invoices.stream(token, tenant_id)
      |> Stream.filter(&(&1["Status"] == "AUTHORISED"))
      |> Enum.to_list()

      # Fetch all pages at once (caution with large datasets)
      {:ok, all} = Xero.Paginator.fetch_all(
        fn opts -> Xero.Accounting.Contacts.list(token, tenant_id, opts) end,
        key: "Contacts"
      )

      # Single page
      {:ok, page} = Xero.Paginator.fetch_page(fetch_fn, page: 2)

  ## High-Volume Threshold

  Xero rejects GET requests that require processing more than 100k records
  (HTTP 400). Use `if_modified_since:`, `where:`, and `summary_only: true`
  to reduce the working set before paginating.
  """

  alias Xero.Error

  @page_size 100

  @type fetch_fn :: (keyword() -> {:ok, term()} | {:error, Error.t()})

  @doc """
  Returns a lazy `Stream` that fetches pages on demand.

  `fetch_fn` receives `[page: integer()]` and must return
  `{:ok, list()}` or `{:error, Error.t()}`.
  """
  @spec stream(fetch_fn(), keyword()) :: Enumerable.t()
  def stream(fetch_fn, opts \\ []) do
    start = opts[:start_page] || 1

    Stream.resource(
      fn -> start end,
      fn
        :done ->
          {:halt, :done}

        page ->
          case fetch_fn.(page: page) do
            {:ok, items} when is_list(items) ->
              if length(items) < @page_size do
                {items, :done}
              else
                {items, page + 1}
              end

            {:ok, _other} ->
              {[], :done}

            {:error, _} ->
              {:halt, page}
          end
      end,
      fn _ -> :ok end
    )
  end

  @doc """
  Fetches all pages and returns a flat list.

  ## Options
  - `:key` — if the fetch_fn returns a map, extract items at this string key
  - `:start_page` — page to begin at (default 1)
  """
  @spec fetch_all(fetch_fn(), keyword()) :: {:ok, list()} | {:error, Error.t()}
  def fetch_all(fetch_fn, opts \\ []) do
    key = opts[:key]
    start = opts[:start_page] || 1
    do_fetch_all(fetch_fn, key, start, [])
  end

  @doc "Fetches a single page."
  @spec fetch_page(fetch_fn(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def fetch_page(fetch_fn, opts \\ []), do: fetch_fn.(page: opts[:page] || 1)

  @doc "Returns the fixed Xero page size (100)."
  @spec page_size() :: 100
  def page_size, do: @page_size

  @spec do_fetch_all(fetch_fn(), String.t() | nil, pos_integer(), list()) ::
          {:ok, list()} | {:error, Error.t()}
  defp do_fetch_all(fetch_fn, key, page, acc) do
    case fetch_fn.(page: page) do
      {:ok, result} ->
        items = extract(result, key)

        if length(items) < @page_size,
          do: {:ok, acc ++ items},
          else: do_fetch_all(fetch_fn, key, page + 1, acc ++ items)

      {:error, _} = err ->
        err
    end
  end

  @spec extract(term(), String.t() | nil) :: list()
  defp extract(result, nil) when is_list(result), do: result
  defp extract(result, nil) when is_map(result), do: [result]
  defp extract(result, key) when is_map(result), do: Map.get(result, key, [])
  defp extract(result, _) when is_list(result), do: result
end
