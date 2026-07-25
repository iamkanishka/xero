defmodule Xero.Accounting.Invoices do
  @moduledoc """
  Xero Accounting API – Invoices.

  Types: `ACCREC` (sales invoices to customers) | `ACCPAY` (bills from suppliers)

  ## Status Flow

      DRAFT → SUBMITTED → AUTHORISED → PAID
                               ↓
                            VOIDED

  ## Key Xero Rules

  - Multiple-invoice GET returns contact summary only (no line items).
    Use `page:` parameter to get full line items in bulk.
  - Maximum **50 invoices per PUT** (counts as 1 API call).
  - `summary_only: true` skips computation-heavy fields for fast responses.
  - `if_modified_since:` enables efficient incremental sync.
  - Requests requiring processing of **>100k invoices** are rejected (HTTP 400).
    Use filters, paging, and `summary_only` to reduce working set size.

  ## Examples

      # List AUTHORISED invoices (page 1, with full line items)
      {:ok, result} = Xero.Accounting.Invoices.list(token, tenant_id,
        statuses: ["AUTHORISED"], page: 1)

      # Incremental sync: only changed since last run
      {:ok, result} = Xero.Accounting.Invoices.list(token, tenant_id,
        if_modified_since: last_sync_datetime)

      # Get a single invoice (full line items always included)
      {:ok, %{"Invoices" => [inv]}} = Xero.Accounting.Invoices.get(token, tenant_id, invoice_id)

      # Get as PDF
      {:ok, %{body: pdf_bytes}} = Xero.Accounting.Invoices.get(token, tenant_id, id, format: :pdf)

      # Create invoices (up to 50 at once)
      {:ok, _} = Xero.Accounting.Invoices.create(token, tenant_id, %{
        "Type"      => "ACCREC",
        "Contact"   => %{"ContactID" => "uuid"},
        "LineItems" => [%{
          "Description" => "Consulting",
          "Quantity"    => 1.0,
          "UnitAmount"  => 500.0,
          "AccountCode" => "200"
        }],
        "Status" => "AUTHORISED"
      })

      # Stream all PAID invoices lazily
      Xero.Accounting.Invoices.stream(token, tenant_id, statuses: ["PAID"])
      |> Enum.each(&process/1)
  """

  use Xero.API.Base, api: :accounting

  @doc """
  Lists invoices. Returns summary-only data for multiple invoices unless
  `:page` is specified (paging returns full line item details).

  ## Options

  - `:page` — Page number (1-indexed, 100/page). Enables full line item details.
  - `:statuses` — List of statuses: `["DRAFT", "AUTHORISED", "PAID", ...]`
  - `:contact_ids` — List of contact UUIDs
  - `:invoice_numbers` — List of invoice numbers
  - `:ids` — List of invoice UUIDs
  - `:reference` — Reference field exact match
  - `:summary_only` — Return lightweight response (boolean)
  - `:order` — Order by field, e.g. `"Date DESC"`, `"UpdatedDateUTC ASC"`
  - `:where` — OData filter: `~s(AmountDue > 0 AND Status == "AUTHORISED")`
  - `:created_by_my_app` — Only return invoices created by this app (boolean)
  - `:if_modified_since` — `DateTime.t()` — only return records modified after this time
  - `:unit_dp` — Number of decimal places for unit amounts (4 default)
  """
  @spec list(Token.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def list(%Token{} = token, tenant_id, opts \\ []) do
    params = %{
      "page" => opts[:page],
      "Statuses" => format_list(opts[:statuses]),
      "ContactIDs" => format_list(opts[:contact_ids]),
      "InvoiceNumbers" => format_list(opts[:invoice_numbers]),
      "IDs" => format_list(opts[:ids]),
      "Reference" => opts[:reference],
      "summaryOnly" => opts[:summary_only],
      "order" => opts[:order],
      "where" => opts[:where],
      "createdByMyApp" => opts[:created_by_my_app],
      "unitdp" => opts[:unit_dp]
    }

    result =
      case opts[:if_modified_since] do
        nil -> req_get(token, tenant_id, "/Invoices", params)
        since -> req_get_modified(token, tenant_id, "/Invoices", since, params)
      end

    ok_body(result)
  end

  @doc """
  Retrieves a single invoice by ID or invoice number.

  Always returns full line item details.

  ## Options

  - `:format` — `:pdf` to receive the invoice as a PDF binary
  - `:unit_dp` — Decimal places for unit amounts (4 default)
  """
  @spec get(Token.t(), String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def get(%Token{} = token, tenant_id, invoice_id, opts \\ []) do
    extra = if opts[:format] == :pdf, do: [{"accept", "application/pdf"}], else: []
    params = %{"unitdp" => opts[:unit_dp]}

    ok_body(
      Client.get(url("/Invoices/#{invoice_id}"), token, extra,
        tenant_id: tenant_id,
        params: clean_params(params)
      )
    )
  end

  @doc """
  Creates one or more invoices (up to 50 per request, counts as 1 API call).

  Pass a single map for one invoice, or a list of maps for bulk creation.
  Uses PUT (Xero's convention for creates with list response).

  ## Required fields

  - `"Type"` — `"ACCREC"` or `"ACCPAY"`
  - `"Contact"` — `%{"ContactID" => "uuid"}` or `%{"Name" => "Supplier Ltd"}`
  - `"LineItems"` — List of line item maps

  ## Optional fields

  - `"Date"`, `"DueDate"` — ISO 8601 date strings
  - `"Status"` — `"DRAFT"` (default) | `"SUBMITTED"` | `"AUTHORISED"`
  - `"Reference"`, `"CurrencyCode"`, `"BrandingThemeID"`
  - `"LineAmountTypes"` — `"Exclusive"` | `"Inclusive"` | `"NoTax"`
  - `"SentToContact"` — Mark invoice as sent (boolean)
  - `"Url"` — Link to an external resource
  """
  @spec create(Token.t(), String.t(), map() | list(map()), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def create(%Token{} = token, tenant_id, invoice_or_invoices, opts \\ []) do
    invoices = List.wrap(invoice_or_invoices)

    body = %{
      "Invoices" => Enum.map(invoices, &normalise_invoice/1),
      "SummarizeErrors" => opts[:summarize_errors] != false
    }

    ok_body(put(token, tenant_id, "/Invoices", body))
  end

  @doc """
  Updates an existing invoice.

  Only DRAFT and SUBMITTED invoices can be fully updated.
  AUTHORISED invoices: only `Reference`, `SentToContact`, `Url`, and `Status` can change.
  """
  @spec update(Token.t(), String.t(), String.t(), map()) :: {:ok, map()} | {:error, Error.t()}
  def update(%Token{} = token, tenant_id, invoice_id, attrs) do
    body = %{"Invoices" => [Map.put(normalise_invoice(attrs), "InvoiceID", invoice_id)]}
    ok_body(post(token, tenant_id, "/Invoices/#{invoice_id}", body))
  end

  @doc "Voids an AUTHORISED invoice."
  @spec void(Token.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def void(%Token{} = t, tid, id), do: update(t, tid, id, %{"Status" => "VOIDED"})

  @doc "Deletes a DRAFT or SUBMITTED invoice."
  @spec delete(Token.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def delete(%Token{} = t, tid, id), do: update(t, tid, id, %{"Status" => "DELETED"})

  @doc """
  Emails an ACCREC invoice to the contact's primary email address.

  Invoice must be type `ACCREC` and status `SUBMITTED`, `AUTHORISED`, or `PAID`.
  Also sends to contact persons with `IncludeInEmails: true`.
  """
  @spec email(Token.t(), String.t(), String.t()) :: :ok | {:error, Error.t()}
  def email(%Token{} = token, tenant_id, invoice_id) do
    case post(token, tenant_id, "/Invoices/#{invoice_id}/Email", %{}) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @doc "Returns the online payment URL for an AUTHORISED ACCREC invoice."
  @spec online_url(Token.t(), String.t(), String.t()) :: {:ok, String.t()} | {:error, Error.t()}
  def online_url(%Token{} = token, tenant_id, invoice_id) do
    case ok_body(req_get(token, tenant_id, "/Invoices/#{invoice_id}/OnlineInvoice")) do
      {:ok, %{"OnlineInvoices" => [%{"OnlineInvoiceUrl" => u}]}} -> {:ok, u}
      {:ok, other} -> {:error, %Error{type: :unknown, message: "Unexpected response", raw: other}}
      err -> err
    end
  end

  @doc "Returns the audit history for an invoice."
  @spec history(Token.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def history(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/Invoices/#{id}/History"))

  @doc "Adds a note to an invoice's history."
  @spec add_note(Token.t(), String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Error.t()}
  def add_note(%Token{} = t, tid, id, note) do
    ok_body(put(t, tid, "/Invoices/#{id}/History", %{"HistoryRecords" => [%{"Details" => note}]}))
  end

  @doc "Lists attachments on an invoice."
  @spec attachments(Token.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def attachments(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/Invoices/#{id}/Attachments"))

  @doc "Uploads an attachment to an invoice."
  @spec upload_attachment(Token.t(), String.t(), String.t(), String.t(), binary(), String.t()) ::
          {:ok, map()} | {:error, Error.t()}
  def upload_attachment(%Token{} = t, tid, id, filename, content, content_type) do
    ok_body(
      Client.post(
        url("/Invoices/#{id}/Attachments/#{filename}"),
        content,
        t,
        [{"content-type", content_type}],
        tenant_id: tid
      )
    )
  end

  @doc "Gets a specific attachment by filename."
  @spec get_attachment(Token.t(), String.t(), String.t(), String.t()) ::
          {:ok, binary()} | {:error, Error.t()}
  def get_attachment(%Token{} = t, tid, id, filename) do
    case Client.get(
           url("/Invoices/#{id}/Attachments/#{filename}"),
           t,
           [{"accept", "application/octet-stream"}],
           tenant_id: tid
         ) do
      {:ok, %{body: b}} -> {:ok, b}
      err -> err
    end
  end

  @doc """
  Returns a lazy `Stream` of all invoices, auto-paginating through results.

  Accepts all options from `list/3` except `:page`.

  ## Example

      Xero.Accounting.Invoices.stream(token, tenant_id,
        statuses: ["AUTHORISED", "PAID"],
        if_modified_since: last_sync)
      |> Stream.filter(&(&1["AmountDue"] > 0))
      |> Enum.each(&sync_invoice/1)
  """
  @spec stream(Token.t(), String.t(), keyword()) :: Enumerable.t()
  def stream(%Token{} = token, tenant_id, opts \\ []) do
    Paginator.stream(fn page_opts ->
      case list(token, tenant_id, Keyword.merge(opts, page_opts)) do
        {:ok, %{"Invoices" => items}} -> {:ok, items}
        other -> other
      end
    end)
  end

  defp normalise_invoice(attrs) when is_map(attrs) do
    attrs
    |> Enum.map(fn {k, v} -> {camelize(k), v} end)
    |> Map.new()
  end
end
