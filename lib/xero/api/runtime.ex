defmodule Xero.API.Runtime do
  @moduledoc """
  Shared request/response plumbing for all Xero API resource modules.

  This used to live inline inside `Xero.API.Base`'s `quote do ... end` block
  and get re-injected (re-compiled, re-inferred) into every single resource
  module via `use Xero.API.Base`. That meant ~30 duplicate private copies of
  the same logic, each independently type-inferred by Dialyzer, and any
  diagnostic pointing into one of those copies collapsed onto the `use` call
  site instead of a real line (macro-injected code has no line metadata
  unless the quote uses `location: :keep`).

  Pulling the logic out into a normal, single, fully-specced module fixes
  both problems: Dialyzer infers/checks this exactly once, and every
  diagnostic points at a real line in this file. `Xero.API.Base` now just
  injects trivial one-line delegates that close over the `:api` atom.
  """

  alias Xero.Auth.Token
  alias Xero.Error
  alias Xero.HTTP.Client

  @spec url(atom(), String.t()) :: String.t()
  def url(api, path), do: Client.base_url(api) <> path

  @spec get(atom(), Token.t(), String.t() | nil, String.t(), map()) :: Client.result()
  def get(api, %Token{} = token, tenant_id, path, params \\ %{}) do
    Client.get(url(api, path), token, [], tenant_id: tenant_id, params: clean_params(params))
  end

  @spec get_modified(
          atom(),
          Token.t(),
          String.t() | nil,
          String.t(),
          DateTime.t() | String.t(),
          map()
        ) ::
          Client.result()
  def get_modified(api, %Token{} = token, tenant_id, path, since, params \\ %{}) do
    Client.get(url(api, path), token, [],
      tenant_id: tenant_id,
      params: clean_params(params),
      if_modified_since: since
    )
  end

  @spec post(atom(), Token.t(), String.t() | nil, String.t(), term()) :: Client.result()
  def post(api, %Token{} = token, tenant_id, path, body) do
    Client.post(url(api, path), body, token, [], tenant_id: tenant_id)
  end

  @spec put(atom(), Token.t(), String.t() | nil, String.t(), term()) :: Client.result()
  def put(api, %Token{} = token, tenant_id, path, body) do
    Client.put(url(api, path), body, token, [], tenant_id: tenant_id)
  end

  @spec delete(atom(), Token.t(), String.t() | nil, String.t()) :: Client.result()
  def delete(api, %Token{} = token, tenant_id, path) do
    Client.delete(url(api, path), token, [], tenant_id: tenant_id)
  end

  @doc "Decodes a JSON body on success; passes non-JSON bodies through raw (e.g. PDF)."
  @spec ok_body(Client.result()) :: {:ok, term()} | {:error, Error.t()}
  def ok_body({:ok, %{body: body}}) do
    case Jason.decode(body) do
      {:ok, parsed} -> {:ok, parsed}
      {:error, _} -> {:ok, body}
    end
  end

  def ok_body({:error, _} = err), do: err

  @doc "Passes the body through raw and undecoded — for XML-returning endpoints."
  @spec ok_xml(Client.result()) :: {:ok, term()} | {:error, Error.t()}
  def ok_xml({:ok, %{body: body}}), do: {:ok, body}
  def ok_xml({:error, _} = err), do: err

  @spec clean_params(map() | keyword()) :: map()
  def clean_params(params) do
    params
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end

  @spec camelize(atom() | String.t()) :: String.t()
  def camelize(k) when is_atom(k), do: k |> Atom.to_string() |> camelize()

  def camelize(k) when is_binary(k),
    do: k |> String.split("_") |> Enum.map(&String.capitalize/1) |> Enum.join()

  @spec format_list(nil | list()) :: String.t() | nil
  def format_list(nil), do: nil
  def format_list([]), do: nil
  def format_list(list), do: Enum.join(list, ",")
end
