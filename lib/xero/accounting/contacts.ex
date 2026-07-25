defmodule Xero.Accounting.Contacts do
  @moduledoc """
  Xero Accounting API – Contacts (customers and/or suppliers).

  **Key rules:** Requests touching >100k contacts rejected (HTTP 400).
  Use `page:`, `where:`, and `summary_only: true` for large orgs.
  """

  use Xero.API.Base, api: :accounting

  @doc """
  Lists contacts. Options: `:page`, `:ids`, `:account_number`, `:summary_only`,
  `:include_archived`, `:order`, `:where`, `:search_term`, `:if_modified_since`
  """
  @spec list(Token.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def list(%Token{} = token, tenant_id, opts \\ []) do
    params = %{
      "page" => opts[:page],
      "IDs" => format_list(opts[:ids]),
      "AccountNumber" => opts[:account_number],
      "summaryOnly" => opts[:summary_only],
      "includeArchived" => opts[:include_archived],
      "order" => opts[:order],
      "where" => opts[:where],
      "searchTerm" => opts[:search_term]
    }

    result =
      case opts[:if_modified_since] do
        nil -> req_get(token, tenant_id, "/Contacts", params)
        since -> req_get_modified(token, tenant_id, "/Contacts", since, params)
      end

    ok_body(result)
  end

  @doc "Retrieves a single contact by ID or account number."
  @spec get(Token.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(%Token{} = token, tenant_id, contact_id),
    do: ok_body(req_get(token, tenant_id, "/Contacts/#{contact_id}"))

  @doc "Creates one or more contacts. Requires `:name` (unique per org)."
  @spec create(Token.t(), String.t(), map() | list(map())) :: {:ok, map()} | {:error, Error.t()}
  def create(%Token{} = token, tenant_id, contact_or_contacts) do
    contacts = Enum.map(List.wrap(contact_or_contacts), &normalise/1)
    ok_body(put(token, tenant_id, "/Contacts", %{"Contacts" => contacts}))
  end

  @doc "Updates a contact."
  @spec update(Token.t(), String.t(), String.t(), map()) :: {:ok, map()} | {:error, Error.t()}
  def update(%Token{} = token, tenant_id, contact_id, attrs) do
    body = %{"Contacts" => [Map.put(normalise(attrs), "ContactID", contact_id)]}
    ok_body(post(token, tenant_id, "/Contacts/#{contact_id}", body))
  end

  @doc "Archives a contact."
  @spec archive(Token.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def archive(%Token{} = token, tenant_id, contact_id),
    do: update(token, tenant_id, contact_id, %{"ContactStatus" => "ARCHIVED"})

  @doc "Returns CIS settings for a contact (UK only)."
  @spec cis_settings(Token.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def cis_settings(%Token{} = token, tenant_id, contact_id),
    do: ok_body(req_get(token, tenant_id, "/Contacts/#{contact_id}/CISSettings"))

  @doc "Updates CIS settings for a contact (UK only)."
  @spec update_cis_settings(Token.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Error.t()}
  def update_cis_settings(%Token{} = token, tenant_id, contact_id, attrs),
    do: ok_body(post(token, tenant_id, "/Contacts/#{contact_id}/CISSettings", attrs))

  @doc "Returns audit history for a contact."
  @spec history(Token.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def history(%Token{} = token, tenant_id, contact_id),
    do: ok_body(req_get(token, tenant_id, "/Contacts/#{contact_id}/History"))

  @doc "Adds a note to a contact's history."
  @spec add_note(Token.t(), String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Error.t()}
  def add_note(%Token{} = token, tenant_id, contact_id, note),
    do:
      ok_body(
        put(token, tenant_id, "/Contacts/#{contact_id}/History", %{
          "HistoryRecords" => [%{"Details" => note}]
        })
      )

  @doc "Lists attachments on a contact."
  @spec attachments(Token.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def attachments(%Token{} = token, tenant_id, contact_id),
    do: ok_body(req_get(token, tenant_id, "/Contacts/#{contact_id}/Attachments"))

  @doc "Uploads an attachment to a contact."
  @spec upload_attachment(Token.t(), String.t(), String.t(), String.t(), binary(), String.t()) ::
          {:ok, map()} | {:error, Error.t()}
  def upload_attachment(%Token{} = token, tenant_id, contact_id, filename, content, content_type) do
    ok_body(
      Client.post(
        url("/Contacts/#{contact_id}/Attachments/#{filename}"),
        content,
        token,
        [{"content-type", content_type}],
        tenant_id: tenant_id
      )
    )
  end

  @doc "Lazy stream of all contacts."
  @spec stream(Token.t(), String.t(), keyword()) :: Enumerable.t()
  def stream(%Token{} = token, tenant_id, opts \\ []) do
    Paginator.stream(fn page_opts ->
      case list(token, tenant_id, Keyword.merge(opts, page_opts)) do
        {:ok, %{"Contacts" => items}} -> {:ok, items}
        other -> other
      end
    end)
  end

  defp normalise(attrs) do
    attrs |> Enum.map(fn {k, v} -> {camelize(k), v} end) |> Map.new()
  end
end
