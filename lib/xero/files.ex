defmodule Xero.Files do
  @moduledoc """
  Xero Files API – Document library, folders, and accounting object associations.
  Base URL: `https://api.xero.com/files.xro/1.0/`
  Scopes: `files` or `files.read`

  ## Examples

      # Upload a file to the inbox
      {:ok, file} = Xero.Files.upload(token, tenant_id, "invoice.pdf", pdf_bytes, "application/pdf")

      # Associate with an accounting object
      :ok = Xero.Files.associate(token, tenant_id, file["FileId"], invoice_id, "Invoice")

      # Download the file content
      {:ok, binary} = Xero.Files.download(token, tenant_id, file["FileId"])

      # Move to a folder
      {:ok, _} = Xero.Files.move_to_folder(token, tenant_id, file["FileId"], folder_id)
  """

  use Xero.API.Base, api: :files

  # ─── Files ───────────────────────────────────────────────────────────────────

  @doc """
  Lists files. Options: `:page_size`, `:page`, `:sort`, `:sort_direction`
  Sort values: `"CreatedDateUtc"` | `"UpdatedDateUtc"` | `"Name"`
  """
  @spec list(Token.t(), String.t(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def list(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Files", %{
        "pagesize" => opts[:page_size],
        "page" => opts[:page],
        "sort" => opts[:sort],
        "sortdirection" => opts[:sort_direction]
      })
    )
  end

  @doc "Retrieves metadata for a single file by ID."
  @spec get(Token.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Files/#{id}"))

  @doc "Downloads the raw binary content of a file."
  @spec download(Token.t(), String.t(), String.t()) :: {:ok, binary()} | {:error, Error.t()}
  def download(%Token{} = t, tid, id) do
    case Client.get(url("/Files/#{id}/Content"), t, [{"accept", "application/octet-stream"}],
           tenant_id: tid
         ) do
      {:ok, %{body: b}} -> {:ok, b}
      err -> err
    end
  end

  @doc """
  Uploads a file to the Xero file library (inbox by default).

  ## Parameters

  - `filename` — File name including extension (e.g. `"invoice.pdf"`)
  - `content` — Binary file content
  - `content_type` — MIME type (e.g. `"application/pdf"`, `"image/jpeg"`)
  """
  @spec upload(Token.t(), String.t(), String.t(), binary(), String.t()) ::
          {:ok, map()} | {:error, Error.t()}
  def upload(%Token{} = t, tid, filename, content, content_type) do
    ok_body(
      Client.post(
        url("/Files"),
        content,
        t,
        [{"content-type", content_type}, {"x-filename", filename}],
        tenant_id: tid
      )
    )
  end

  @doc "Uploads a file directly into a specific folder."
  @spec upload_to_folder(Token.t(), String.t(), String.t(), String.t(), binary(), String.t()) ::
          {:ok, map()} | {:error, Error.t()}
  def upload_to_folder(%Token{} = t, tid, folder_id, filename, content, content_type) do
    ok_body(
      Client.post(
        url("/Folders/#{folder_id}/Files"),
        content,
        t,
        [{"content-type", content_type}, {"x-filename", filename}],
        tenant_id: tid
      )
    )
  end

  @doc "Renames a file."
  @spec rename(Token.t(), String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Error.t()}
  def rename(%Token{} = t, tid, id, new_name),
    do: ok_body(put(t, tid, "/Files/#{id}", %{"Name" => new_name}))

  @doc "Moves a file to a different folder."
  @spec move_to_folder(Token.t(), String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Error.t()}
  def move_to_folder(%Token{} = t, tid, file_id, folder_id),
    do: ok_body(put(t, tid, "/Files/#{file_id}", %{"FolderId" => folder_id}))

  @doc "Deletes a file from the library."
  @spec delete(Token.t(), String.t(), String.t()) :: :ok | {:error, Error.t()}
  def delete(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/Files/#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ─── Folders ─────────────────────────────────────────────────────────────────

  @doc "Lists all folders. Options: `:sort`"
  @spec folders(Token.t(), String.t(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def folders(%Token{} = t, tid, opts \\ []),
    do: ok_body(req_get(t, tid, "/Folders", %{"sort" => opts[:sort]}))

  @doc "Retrieves a specific folder by ID."
  @spec folder(Token.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def folder(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Folders/#{id}"))

  @doc "Creates a new folder."
  @spec create_folder(Token.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def create_folder(%Token{} = t, tid, name),
    do: ok_body(post(t, tid, "/Folders", %{"Name" => name}))

  @doc "Renames a folder."
  @spec rename_folder(Token.t(), String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Error.t()}
  def rename_folder(%Token{} = t, tid, id, new_name),
    do: ok_body(put(t, tid, "/Folders/#{id}", %{"Name" => new_name}))

  @doc "Deletes a folder (must be empty)."
  @spec delete_folder(Token.t(), String.t(), String.t()) :: :ok | {:error, Error.t()}
  def delete_folder(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/Folders/#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @doc "Lists files in a specific folder."
  @spec files_in_folder(Token.t(), String.t(), String.t(), keyword()) ::
          {:ok, term()} | {:error, Error.t()}
  def files_in_folder(%Token{} = t, tid, folder_id, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Folders/#{folder_id}/Files", %{
        "pagesize" => opts[:page_size],
        "page" => opts[:page]
      })
    )
  end

  @doc "Returns the inbox folder metadata."
  @spec inbox(Token.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def inbox(%Token{} = t, tid), do: ok_body(req_get(t, tid, "/Inbox"))

  @doc "Lists files in the inbox."
  @spec inbox_files(Token.t(), String.t(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def inbox_files(%Token{} = t, tid, opts \\ []) do
    case inbox(t, tid) do
      {:ok, %{"Id" => inbox_id}} ->
        files_in_folder(t, tid, inbox_id, opts)

      {:ok, inbox_data} ->
        id = inbox_data["Id"] || inbox_data["id"]

        if id,
          do: files_in_folder(t, tid, id, opts),
          else: {:error, Error.config_error("Could not determine inbox folder ID")}

      err ->
        err
    end
  end

  # ─── Associations ─────────────────────────────────────────────────────────────

  @doc """
  Associates a file with a Xero accounting object.

  ## Object Types

  `"Account"` | `"BankTransaction"` | `"Contact"` | `"CreditNote"` |
  `"Invoice"` | `"ManualJournal"` | `"Receipt"` | `"RepeatingInvoice"`
  """
  @spec associate(Token.t(), String.t(), String.t(), String.t(), String.t()) ::
          :ok | {:error, Error.t()}
  def associate(%Token{} = t, tid, file_id, object_id, object_type) do
    case post(t, tid, "/Files/#{file_id}/Associations", %{
           "ObjectId" => object_id,
           "ObjectGroup" => object_type
         }) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @doc "Lists all file associations for an accounting object."
  @spec associations(Token.t(), String.t(), String.t()) :: {:ok, term()} | {:error, Error.t()}
  def associations(%Token{} = t, tid, object_id),
    do: ok_body(req_get(t, tid, "/Associations/#{object_id}"))

  @doc "Removes a file association from an accounting object."
  @spec disassociate(Token.t(), String.t(), String.t(), String.t()) :: :ok | {:error, Error.t()}
  def disassociate(%Token{} = t, tid, file_id, object_id) do
    case req_delete(t, tid, "/Files/#{file_id}/Associations/#{object_id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @doc "Lists all associations across all files for an object group."
  @spec list_associations_for_object(Token.t(), String.t(), String.t(), String.t()) ::
          {:ok, term()} | {:error, Error.t()}
  def list_associations_for_object(%Token{} = t, tid, object_id, object_type) do
    ok_body(req_get(t, tid, "/Associations/#{object_id}", %{"ObjectGroup" => object_type}))
  end
end
