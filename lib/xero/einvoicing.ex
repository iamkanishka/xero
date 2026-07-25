defmodule Xero.EInvoicing do
  @moduledoc """
  Xero eInvoicing API – PEPPOL BIS 3.0 / UBL 2.1 electronic invoicing.
  Base URL: `https://api.xero.com/einvoicing`
  Scope: `einvoicing.documents`

  Available primarily for AU and NZ organisations on the PEPPOL network.
  UK support is in progress — check Xero documentation for current availability.

  ## What is eInvoicing?

  eInvoicing is the automated digital exchange of structured invoices between
  accounting systems via the PEPPOL network. No email, no PDFs, no manual data entry.
  The format is PEPPOL BIS 3.0 (UBL 2.1 XML).

  ## PEPPOL Participant IDs

  Format: `scheme:value`
  - AU ABN: `"0151:12345678901"` (11 digits)
  - AU ARBN: `"0151:12345678"` (9 digits)
  - NZ IRD: `"0088:1234567890"` (NZBN)
  - GLN: `"0088:1234567890123"`

  ## Workflow

  1. `lookup_participant/3` — verify recipient is on PEPPOL
  2. Ensure your invoice is AUTHORISED in Xero
  3. `send_document/3` — send the invoice
  4. `get_document_status/3` — poll until `"DELIVERED"` or `"FAILED"`
  5. For inbound: `list_documents/3` with `direction: "RECEIVED"`, then `acknowledge_document/3`

  ## Document Statuses

  | Status | Description |
  |--------|-------------|
  | `"SENT"` | Document transmitted to PEPPOL network |
  | `"DELIVERED"` | Recipient's access point confirmed delivery |
  | `"FAILED"` | Delivery failed — see error details |
  | `"REJECTED"` | Recipient rejected the document |
  """

  use Xero.API.Base, api: :einvoicing

  @doc """
  Checks if a business is registered as a PEPPOL participant.

  ## Parameters

  - `participant_id` — PEPPOL participant ID in `scheme:value` format
    e.g. `"0151:12345678901"` (AU ABN) or `"0088:1234567890123"` (GLN)

  Returns participant details if registered, or `:not_found` error if not.
  """
  @spec lookup_participant(Token.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Error.t()}
  def lookup_participant(%Token{} = t, tid, participant_id) do
    ok_body(req_get(t, tid, "/documents/Participants", %{"participantId" => participant_id}))
  end

  @doc """
  Returns the PEPPOL registration details for the connected organisation itself.
  Use this to check if your organisation is properly registered on the PEPPOL network.
  """
  @spec get_organisation_participant(Token.t(), String.t()) ::
          {:ok, map()} | {:error, Error.t()}
  def get_organisation_participant(%Token{} = t, tid),
    do: ok_body(req_get(t, tid, "/documents/Participants/Organisation"))

  @doc """
  Lists sent and/or received e-invoicing documents.

  ## Options

  - `:direction` — `"SENT"` | `"RECEIVED"` (omit for both)
  - `:status` — `"SENT"` | `"DELIVERED"` | `"FAILED"` | `"REJECTED"`
  - `:date_from` / `:date_to` — Date range (YYYY-MM-DD)
  - `:page` — Page number
  - `:page_size` — Items per page (max 100)
  """
  @spec list_documents(Token.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def list_documents(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/documents", %{
        "Direction" => opts[:direction],
        "Status" => opts[:status],
        "DateFrom" => opts[:date_from],
        "DateTo" => opts[:date_to],
        "page" => opts[:page],
        "pageSize" => opts[:page_size]
      })
    )
  end

  @doc "Retrieves a single e-invoicing document by ID."
  @spec get_document(Token.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get_document(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/documents/#{id}"))

  @doc """
  Gets the delivery status of a sent e-invoice.

  Poll this after `send_document/3` until status is `"DELIVERED"` or `"FAILED"`.
  Recommended polling interval: 30 seconds for first 5 minutes, then 5 minutes.
  """
  @spec get_document_status(Token.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Error.t()}
  def get_document_status(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/documents/#{id}/status"))

  @doc """
  Sends an AUTHORISED Xero invoice as a PEPPOL e-invoice to the recipient.

  The invoice must already exist in Xero with status `AUTHORISED`.
  The contact must have a valid PEPPOL participant ID configured.

  ## Required fields

  - `"invoiceId"` — UUID of the AUTHORISED Xero invoice to send

  ## Optional fields

  - `"documentType"` — PEPPOL document type code (default: standard invoice)
  """
  @spec send_document(Token.t(), String.t(), map()) :: {:ok, map()} | {:error, Error.t()}
  def send_document(%Token{} = t, tid, attrs), do: ok_body(post(t, tid, "/documents", attrs))

  @doc """
  Downloads the raw UBL 2.1 XML for an e-invoicing document.

  Returns binary XML suitable for archiving, forwarding, or compliance storage.
  """
  @spec download_document(Token.t(), String.t(), String.t()) ::
          {:ok, binary()} | {:error, Error.t()}
  def download_document(%Token{} = t, tid, id) do
    case Client.get(url("/documents/#{id}/content"), t, [{"accept", "application/xml"}],
           tenant_id: tid
         ) do
      {:ok, %{body: b}} -> {:ok, b}
      err -> err
    end
  end

  @doc """
  Acknowledges receipt of an inbound e-invoice.

  Acknowledge inbound documents once processed to prevent re-delivery.
  Should be called after successfully importing the invoice into your system.
  """
  @spec acknowledge_document(Token.t(), String.t(), String.t()) :: :ok | {:error, Error.t()}
  def acknowledge_document(%Token{} = t, tid, id) do
    case post(t, tid, "/documents/#{id}/Acknowledge", %{}) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @doc """
  Rejects an inbound e-invoice.

  Use this when you receive an invoice that you cannot process
  (e.g. wrong recipient, duplicate, incorrect details).

  ## Required fields

  - `"rejectReason"` — Reason code for rejection
  - `"rejectDescription"` — Human-readable rejection description
  """
  @spec reject_document(Token.t(), String.t(), String.t(), map()) ::
          :ok | {:error, Error.t()}
  def reject_document(%Token{} = t, tid, id, attrs) do
    case post(t, tid, "/documents/#{id}/Reject", attrs) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
