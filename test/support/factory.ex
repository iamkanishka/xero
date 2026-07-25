defmodule Xero.Test.Factory do
  @moduledoc "Test data factories for Xero API response shapes."

  import Bitwise

  alias Xero.Auth.Token

  # --- Tokens ---

  def valid_token(overrides \\ %{}) do
    Map.merge(
      %Token{
        access_token: "test-access-token-abc123",
        refresh_token: "test-refresh-token-xyz789",
        expires_at: DateTime.add(DateTime.utc_now(), 3_600, :second),
        token_type: "Bearer",
        scopes: ~w(openid accounting.transactions accounting.contacts offline_access)
      },
      overrides
    )
  end

  def expired_token do
    %Token{
      access_token: "expired-token",
      refresh_token: "still-valid-refresh",
      expires_at: DateTime.add(DateTime.utc_now(), -120, :second),
      token_type: "Bearer",
      scopes: ["accounting.transactions"]
    }
  end

  def tenant_id, do: "a4d6c7b8-1234-5678-abcd-ef0123456789"

  # --- Connection ---

  def connection(overrides \\ %{}) do
    Map.merge(
      %{
        "id" => "conn-#{System.unique_integer([:positive])}",
        "tenantId" => tenant_id(),
        "tenantType" => "ORGANISATION",
        "tenantName" => "Test Company Ltd",
        "createdDateUtc" => "2024-01-01T00:00:00",
        "updatedDateUtc" => "2024-01-01T00:00:00"
      },
      overrides
    )
  end

  # --- Invoices ---

  def invoice(overrides \\ %{}) do
    Map.merge(
      %{
        "InvoiceID" => uuid(),
        "Type" => "ACCREC",
        "Status" => "AUTHORISED",
        "InvoiceNumber" => "INV-#{System.unique_integer([:positive])}",
        "Reference" => "REF-001",
        "CurrencyCode" => "AUD",
        "CurrencyRate" => 1.0,
        "SubTotal" => 100.0,
        "TotalTax" => 10.0,
        "Total" => 110.0,
        "AmountDue" => 110.0,
        "AmountPaid" => 0.0,
        "AmountCredited" => 0.0,
        "UpdatedDateUTC" => "/Date(1704067200000+0000)/",
        "Date" => "/Date(1704067200000+0000)/",
        "DueDate" => "/Date(1706745600000+0000)/",
        "Contact" => contact_summary(),
        "LineItems" => [line_item()]
      },
      overrides
    )
  end

  def invoice_list(count \\ 3) do
    %{"Invoices" => Enum.map(1..count, fn _ -> invoice() end)}
  end

  # --- Contacts ---

  def contact(overrides \\ %{}) do
    Map.merge(
      %{
        "ContactID" => uuid(),
        "Name" => "Acme Corp #{System.unique_integer([:positive])}",
        "EmailAddress" => "accounts@acme.com",
        "IsCustomer" => true,
        "IsSupplier" => false,
        "ContactStatus" => "ACTIVE",
        "UpdatedDateUTC" => "/Date(1704067200000+0000)/",
        "Phones" => [],
        "Addresses" => []
      },
      overrides
    )
  end

  def contact_summary do
    %{"ContactID" => uuid(), "Name" => "Test Customer"}
  end

  def contact_list(count \\ 3) do
    %{"Contacts" => Enum.map(1..count, fn _ -> contact() end)}
  end

  # --- Line Items ---

  def line_item(overrides \\ %{}) do
    Map.merge(
      %{
        "LineItemID" => uuid(),
        "Description" => "Professional Services",
        "Quantity" => 1.0,
        "UnitAmount" => 100.0,
        "AccountCode" => "200",
        "TaxType" => "OUTPUT",
        "TaxAmount" => 10.0,
        "LineAmount" => 100.0
      },
      overrides
    )
  end

  # --- Accounts ---

  def account(overrides \\ %{}) do
    Map.merge(
      %{
        "AccountID" => uuid(),
        "Code" => "#{Enum.random(100..999)}",
        "Name" => "Test Account",
        "Type" => "REVENUE",
        "Class" => "REVENUE",
        "Status" => "ACTIVE",
        "Description" => "Test account for unit tests",
        "TaxType" => "OUTPUT",
        "EnablePaymentsToAccount" => false,
        "ShowInExpenseClaims" => false,
        "UpdatedDateUTC" => "/Date(1704067200000+0000)/"
      },
      overrides
    )
  end

  # --- Payments ---

  def payment(overrides \\ %{}) do
    Map.merge(
      %{
        "PaymentID" => uuid(),
        "Date" => "/Date(1704067200000+0000)/",
        "Amount" => 110.0,
        "PaymentType" => "ACCRECPAYMENT",
        "Status" => "AUTHORISED",
        "UpdatedDateUTC" => "/Date(1704067200000+0000)/",
        "Invoice" => %{"InvoiceID" => uuid(), "InvoiceNumber" => "INV-001"},
        "Account" => %{"AccountID" => uuid(), "Code" => "090"}
      },
      overrides
    )
  end

  # --- Purchase Orders ---

  def purchase_order(overrides \\ %{}) do
    Map.merge(
      %{
        "PurchaseOrderID" => uuid(),
        "PurchaseOrderNumber" => "PO-#{System.unique_integer([:positive])}",
        "Status" => "AUTHORISED",
        "DateString" => "2024-01-15",
        "Contact" => contact_summary(),
        "LineItems" => [line_item()]
      },
      overrides
    )
  end

  # --- Assets ---

  def asset(overrides \\ %{}) do
    Map.merge(
      %{
        "assetId" => uuid(),
        "assetName" => "Office Equipment #{System.unique_integer([:positive])}",
        "assetNumber" => "ASSET-001",
        "assetStatus" => "DRAFT",
        "purchaseDate" => "2024-01-15",
        "purchasePrice" => 1_200.0,
        "disposalPrice" => 0.0
      },
      overrides
    )
  end

  # --- Projects ---

  def project(overrides \\ %{}) do
    Map.merge(
      %{
        "projectId" => uuid(),
        "name" => "Project #{System.unique_integer([:positive])}",
        "status" => "INPROGRESS",
        "contactId" => uuid(),
        "currency" => "AUD",
        "minutesLogged" => 0,
        "totalTaskAmount" => %{"currency" => "AUD", "value" => 0.0},
        "totalExpenseAmount" => %{"currency" => "AUD", "value" => 0.0}
      },
      overrides
    )
  end

  def task(overrides \\ %{}) do
    Map.merge(
      %{
        "taskId" => uuid(),
        "name" => "Task #{System.unique_integer([:positive])}",
        "chargeType" => "TIME",
        "rate" => %{"currency" => "AUD", "value" => 150.0},
        "status" => "ACTIVE"
      },
      overrides
    )
  end

  def time_entry(overrides \\ %{}) do
    Map.merge(
      %{
        "timeEntryId" => uuid(),
        "taskId" => uuid(),
        "userId" => uuid(),
        "dateUtc" => "2024-01-15T09:00:00Z",
        "duration" => 60,
        "description" => "Development work",
        "isBillable" => true
      },
      overrides
    )
  end

  # --- Helpers ---

  defp uuid do
    <<a::32, b::16, c::16, d::16, e::48>> = :crypto.strong_rand_bytes(16)

    "#{hex(a, 8)}-#{hex(b, 4)}-#{hex(4, 1)}#{hex(c &&& 0x0FFF, 3)}-#{hex(d ||| (0x8000 &&& 0xBFFF), 4)}-#{hex(e, 12)}"
  end

  defp hex(n, len) do
    n
    |> Integer.to_string(16)
    |> String.downcase()
    |> String.pad_leading(len, "0")
  end
end
