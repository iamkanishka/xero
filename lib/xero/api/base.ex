defmodule Xero.API.Base do
  @moduledoc """
  Shared `__using__` macro for all Xero API resource modules.

  Injects `req_get/4`, `post/4`, `put/4`, `req_delete/3`, `ok_body/1`, `url/1`
  and the `base_url/0` helper derived from the `:api` option.

  The request helpers are prefixed with `req_` (`req_get`, `req_get_modified`,
  `req_delete`) so they don't collide with the public `get/3`, `get/4`, and
  `delete/3` functions that resource modules define for their own API surface.

  All real logic lives in `Xero.API.Runtime`, a plain (non-macro) module —
  what's injected here is only thin, single-clause delegates that close over
  the `:api` atom. Keeping the actual implementation out of the `quote` block
  means Dialyzer type-checks it exactly once instead of once per `use` call
  site, and any diagnostic on the real logic points at a real line in
  `runtime.ex` instead of collapsing onto every module's `use` line.

  ## Usage

      defmodule Xero.Accounting.Invoices do
        use Xero.API.Base, api: :accounting
        # now has access to req_get/post/put/req_delete/ok_body/url helpers
      end
  """

  defmacro __using__(opts) do
    api = Keyword.fetch!(opts, :api)

    quote location: :keep do
      alias Xero.API.Runtime
      alias Xero.Auth.Token
      alias Xero.Error
      alias Xero.HTTP.Client
      alias Xero.Paginator

      @api unquote(api)

      @spec base_url() :: String.t()
      defp base_url, do: Client.base_url(@api)

      @spec url(String.t()) :: String.t()
      defp url(path), do: Runtime.url(@api, path)

      @spec req_get(Token.t(), String.t() | nil, String.t(), map()) :: Client.result()
      defp req_get(token, tenant_id, path, params \\ %{}),
        do: Runtime.get(@api, token, tenant_id, path, params)

      @spec req_get_modified(
              Token.t(),
              String.t() | nil,
              String.t(),
              DateTime.t() | String.t(),
              map()
            ) ::
              Client.result()
      defp req_get_modified(token, tenant_id, path, since, params \\ %{}),
        do: Runtime.get_modified(@api, token, tenant_id, path, since, params)

      @spec post(Token.t(), String.t() | nil, String.t(), term()) :: Client.result()
      defp post(token, tenant_id, path, body),
        do: Runtime.post(@api, token, tenant_id, path, body)

      @spec put(Token.t(), String.t() | nil, String.t(), term()) :: Client.result()
      defp put(token, tenant_id, path, body),
        do: Runtime.put(@api, token, tenant_id, path, body)

      @spec req_delete(Token.t(), String.t() | nil, String.t()) :: Client.result()
      defp req_delete(token, tenant_id, path),
        do: Runtime.delete(@api, token, tenant_id, path)

      @spec ok_body(Client.result()) :: {:ok, term()} | {:error, Error.t()}
      defp ok_body(result), do: Runtime.ok_body(result)

      @spec clean_params(map() | keyword()) :: map()
      defp clean_params(params), do: Runtime.clean_params(params)

      @spec camelize(atom() | String.t()) :: String.t()
      defp camelize(k), do: Runtime.camelize(k)

      @spec format_list(nil | list()) :: String.t() | nil
      defp format_list(list), do: Runtime.format_list(list)
    end
  end
end
