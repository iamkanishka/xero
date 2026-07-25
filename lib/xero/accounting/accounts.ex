defmodule Xero.Accounting.Accounts do
  @moduledoc "Xero Accounting API – Chart of Accounts."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    params = %{"where" => opts[:where], "order" => opts[:order]}

    case opts[:if_modified_since] do
      nil -> ok_body(req_get(t, tid, "/Accounts", params))
      since -> ok_body(req_get_modified(t, tid, "/Accounts", since, params))
    end
  end

  def get(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Accounts/#{id}"))

  def create(%Token{} = t, tid, attrs),
    do: ok_body(put(t, tid, "/Accounts", %{"Accounts" => [attrs]}))

  def update(%Token{} = t, tid, id, attrs),
    do: ok_body(post(t, tid, "/Accounts/#{id}", %{"Accounts" => [attrs]}))

  def archive(%Token{} = t, tid, id), do: update(t, tid, id, %{"Status" => "ARCHIVED"})

  def delete(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/Accounts/#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  def attachments(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/Accounts/#{id}/Attachments"))

  def upload_attachment(%Token{} = t, tid, id, filename, content, content_type) do
    ok_body(
      Client.post(
        url("/Accounts/#{id}/Attachments/#{filename}"),
        content,
        t,
        [{"content-type", content_type}],
        tenant_id: tid
      )
    )
  end
end

defmodule Xero.Accounting.BankTransactions do
  @moduledoc "Xero Accounting API – Bank Transactions (SPEND / RECEIVE money)."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    params = %{"page" => opts[:page], "where" => opts[:where], "order" => opts[:order]}

    case opts[:if_modified_since] do
      nil -> ok_body(req_get(t, tid, "/BankTransactions", params))
      since -> ok_body(req_get_modified(t, tid, "/BankTransactions", since, params))
    end
  end

  def get(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/BankTransactions/#{id}"))

  def create(%Token{} = t, tid, txn_or_txns) do
    ok_body(put(t, tid, "/BankTransactions", %{"BankTransactions" => List.wrap(txn_or_txns)}))
  end

  def update(%Token{} = t, tid, id, attrs) do
    ok_body(
      post(t, tid, "/BankTransactions/#{id}", %{
        "BankTransactions" => [Map.put(attrs, "BankTransactionID", id)]
      })
    )
  end

  def delete(%Token{} = t, tid, id) do
    ok_body(
      post(t, tid, "/BankTransactions/#{id}", %{
        "BankTransactions" => [%{"BankTransactionID" => id, "Status" => "DELETED"}]
      })
    )
  end

  def history(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/BankTransactions/#{id}/History"))

  def add_note(%Token{} = t, tid, id, note) do
    ok_body(
      put(t, tid, "/BankTransactions/#{id}/History", %{"HistoryRecords" => [%{"Details" => note}]})
    )
  end

  def attachments(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/BankTransactions/#{id}/Attachments"))

  def upload_attachment(%Token{} = t, tid, id, filename, content, content_type) do
    ok_body(
      Client.post(
        url("/BankTransactions/#{id}/Attachments/#{filename}"),
        content,
        t,
        [{"content-type", content_type}],
        tenant_id: tid
      )
    )
  end

  def stream(%Token{} = t, tid, opts \\ []) do
    Paginator.stream(fn page_opts ->
      case list(t, tid, Keyword.merge(opts, page_opts)) do
        {:ok, %{"BankTransactions" => items}} -> {:ok, items}
        other -> other
      end
    end)
  end
end

defmodule Xero.Accounting.BankTransfers do
  @moduledoc "Xero Accounting API – Bank Transfers between two bank accounts."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    params = %{"where" => opts[:where], "order" => opts[:order]}

    case opts[:if_modified_since] do
      nil -> ok_body(req_get(t, tid, "/BankTransfers", params))
      since -> ok_body(req_get_modified(t, tid, "/BankTransfers", since, params))
    end
  end

  def get(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/BankTransfers/#{id}"))

  def create(%Token{} = t, tid, attrs),
    do: ok_body(put(t, tid, "/BankTransfers", %{"BankTransfers" => [attrs]}))

  def history(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/BankTransfers/#{id}/History"))

  def attachments(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/BankTransfers/#{id}/Attachments"))

  def upload_attachment(%Token{} = t, tid, id, filename, content, content_type) do
    ok_body(
      Client.post(
        url("/BankTransfers/#{id}/Attachments/#{filename}"),
        content,
        t,
        [{"content-type", content_type}],
        tenant_id: tid
      )
    )
  end
end

defmodule Xero.Accounting.Payments do
  @moduledoc "Xero Accounting API – Payments applied to invoices, credit notes, over/prepayments."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    params = %{"page" => opts[:page] || 1, "where" => opts[:where], "order" => opts[:order]}

    case opts[:if_modified_since] do
      nil -> ok_body(req_get(t, tid, "/Payments", params))
      since -> ok_body(req_get_modified(t, tid, "/Payments", since, params))
    end
  end

  def get(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Payments/#{id}"))
  def history(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Payments/#{id}/History"))

  def add_note(%Token{} = t, tid, id, note) do
    ok_body(put(t, tid, "/Payments/#{id}/History", %{"HistoryRecords" => [%{"Details" => note}]}))
  end

  def create(%Token{} = t, tid, payment_or_payments) do
    ok_body(put(t, tid, "/Payments", %{"Payments" => List.wrap(payment_or_payments)}))
  end

  def delete(%Token{} = t, tid, id) do
    ok_body(
      post(t, tid, "/Payments/#{id}", %{
        "Payments" => [%{"PaymentID" => id, "Status" => "DELETED"}]
      })
    )
  end

  def stream(%Token{} = t, tid, opts \\ []) do
    Paginator.stream(fn page_opts ->
      case list(t, tid, Keyword.merge(opts, page_opts)) do
        {:ok, %{"Payments" => items}} -> {:ok, items}
        other -> other
      end
    end)
  end
end

defmodule Xero.Accounting.BatchPayments do
  @moduledoc "Xero Accounting API – Batch Payments."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    params = %{"where" => opts[:where], "order" => opts[:order]}

    case opts[:if_modified_since] do
      nil -> ok_body(req_get(t, tid, "/BatchPayments", params))
      since -> ok_body(req_get_modified(t, tid, "/BatchPayments", since, params))
    end
  end

  def get(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/BatchPayments/#{id}"))

  def create(%Token{} = t, tid, attrs),
    do: ok_body(put(t, tid, "/BatchPayments", %{"BatchPayments" => [attrs]}))

  def history(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/BatchPayments/#{id}/History"))

  def delete(%Token{} = t, tid, id) do
    body = %{"BatchPayments" => [%{"BatchPaymentID" => id, "Status" => "DELETED"}]}

    case post(t, tid, "/BatchPayments", body) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end

defmodule Xero.Accounting.CreditNotes do
  @moduledoc "Xero Accounting API – Credit Notes. Types: ACCRECCREDIT | ACCPAYCREDIT."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/CreditNotes", %{
        "page" => opts[:page],
        "where" => opts[:where],
        "order" => opts[:order]
      })
    )
  end

  def get(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/CreditNotes/#{id}"))

  def create(%Token{} = t, tid, attrs),
    do: ok_body(put(t, tid, "/CreditNotes", %{"CreditNotes" => List.wrap(attrs)}))

  def update(%Token{} = t, tid, id, attrs) do
    ok_body(
      post(t, tid, "/CreditNotes/#{id}", %{"CreditNotes" => [Map.put(attrs, "CreditNoteID", id)]})
    )
  end

  def void(%Token{} = t, tid, id), do: update(t, tid, id, %{"Status" => "VOIDED"})
  def delete(%Token{} = t, tid, id), do: update(t, tid, id, %{"Status" => "DELETED"})

  def allocate(%Token{} = t, tid, id, allocation) do
    ok_body(put(t, tid, "/CreditNotes/#{id}/Allocations", %{"Allocations" => [allocation]}))
  end

  def delete_allocation(%Token{} = t, tid, id, allocation_id) do
    case req_delete(t, tid, "/CreditNotes/#{id}/Allocations/#{allocation_id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  def history(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/CreditNotes/#{id}/History"))

  def add_note(%Token{} = t, tid, id, note) do
    ok_body(
      put(t, tid, "/CreditNotes/#{id}/History", %{"HistoryRecords" => [%{"Details" => note}]})
    )
  end

  def attachments(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/CreditNotes/#{id}/Attachments"))

  def upload_attachment(%Token{} = t, tid, id, filename, content, content_type) do
    ok_body(
      Client.post(
        url("/CreditNotes/#{id}/Attachments/#{filename}"),
        content,
        t,
        [{"content-type", content_type}],
        tenant_id: tid
      )
    )
  end
end

defmodule Xero.Accounting.Overpayments do
  @moduledoc "Xero Accounting API – Overpayments."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Overpayments", %{
        "page" => opts[:page],
        "where" => opts[:where],
        "order" => opts[:order]
      })
    )
  end

  def get(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Overpayments/#{id}"))

  def allocate(%Token{} = t, tid, id, alloc) do
    ok_body(put(t, tid, "/Overpayments/#{id}/Allocations", %{"Allocations" => [alloc]}))
  end

  def delete_allocation(%Token{} = t, tid, id, allocation_id) do
    case req_delete(t, tid, "/Overpayments/#{id}/Allocations/#{allocation_id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  def history(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Overpayments/#{id}/History"))
end

defmodule Xero.Accounting.Prepayments do
  @moduledoc "Xero Accounting API – Prepayments."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Prepayments", %{
        "page" => opts[:page],
        "where" => opts[:where],
        "order" => opts[:order]
      })
    )
  end

  def get(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Prepayments/#{id}"))

  def allocate(%Token{} = t, tid, id, alloc) do
    ok_body(put(t, tid, "/Prepayments/#{id}/Allocations", %{"Allocations" => [alloc]}))
  end

  def delete_allocation(%Token{} = t, tid, id, allocation_id) do
    case req_delete(t, tid, "/Prepayments/#{id}/Allocations/#{allocation_id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  def history(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Prepayments/#{id}/History"))
end

defmodule Xero.Accounting.PurchaseOrders do
  @moduledoc "Xero Accounting API – Purchase Orders. Paging enforced (100/page)."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    params = %{
      "page" => opts[:page] || 1,
      "Status" => opts[:status],
      "DateFrom" => opts[:date_from],
      "DateTo" => opts[:date_to],
      "order" => opts[:order]
    }

    ok_body(req_get(t, tid, "/PurchaseOrders", params))
  end

  def get(%Token{} = t, tid, id, opts \\ []) do
    extra = if opts[:format] == :pdf, do: [{"accept", "application/pdf"}], else: []
    ok_body(Client.get(url("/PurchaseOrders/#{id}"), t, extra, tenant_id: tid))
  end

  def create(%Token{} = t, tid, attrs) do
    ok_body(put(t, tid, "/PurchaseOrders", %{"PurchaseOrders" => List.wrap(attrs)}))
  end

  def update(%Token{} = t, tid, id, attrs) do
    ok_body(
      post(t, tid, "/PurchaseOrders/#{id}", %{
        "PurchaseOrders" => [Map.put(attrs, "PurchaseOrderID", id)]
      })
    )
  end

  def delete(%Token{} = t, tid, id), do: update(t, tid, id, %{"Status" => "DELETED"})

  def email(%Token{} = t, tid, id) do
    case post(t, tid, "/PurchaseOrders/#{id}/Email", %{}) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  def history(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/PurchaseOrders/#{id}/History"))

  def add_note(%Token{} = t, tid, id, note) do
    ok_body(
      put(t, tid, "/PurchaseOrders/#{id}/History", %{"HistoryRecords" => [%{"Details" => note}]})
    )
  end

  def attachments(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/PurchaseOrders/#{id}/Attachments"))

  def upload_attachment(%Token{} = t, tid, id, filename, content, content_type) do
    ok_body(
      Client.post(
        url("/PurchaseOrders/#{id}/Attachments/#{filename}"),
        content,
        t,
        [{"content-type", content_type}],
        tenant_id: tid
      )
    )
  end

  def stream(%Token{} = t, tid, opts \\ []) do
    Paginator.stream(fn page_opts ->
      case list(t, tid, Keyword.merge(opts, page_opts)) do
        {:ok, %{"PurchaseOrders" => items}} -> {:ok, items}
        other -> other
      end
    end)
  end
end

defmodule Xero.Accounting.Quotes do
  @moduledoc "Xero Accounting API – Quotes. Statuses: DRAFT|SENT|DECLINED|ACCEPTED|INVOICED|DELETED."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    params = %{
      "page" => opts[:page],
      "Status" => opts[:status],
      "ContactID" => opts[:contact_id],
      "DateFrom" => opts[:date_from],
      "DateTo" => opts[:date_to],
      "ExpiryDateFrom" => opts[:expiry_date_from],
      "ExpiryDateTo" => opts[:expiry_date_to]
    }

    ok_body(req_get(t, tid, "/Quotes", params))
  end

  def get(%Token{} = t, tid, id, opts \\ []) do
    extra = if opts[:format] == :pdf, do: [{"accept", "application/pdf"}], else: []
    ok_body(Client.get(url("/Quotes/#{id}"), t, extra, tenant_id: tid))
  end

  def create(%Token{} = t, tid, attrs),
    do: ok_body(put(t, tid, "/Quotes", %{"Quotes" => List.wrap(attrs)}))

  def update(%Token{} = t, tid, id, attrs) do
    ok_body(post(t, tid, "/Quotes/#{id}", %{"Quotes" => [Map.put(attrs, "QuoteID", id)]}))
  end

  def void(%Token{} = t, tid, id), do: update(t, tid, id, %{"Status" => "DECLINED"})
  def delete(%Token{} = t, tid, id), do: update(t, tid, id, %{"Status" => "DELETED"})

  def email(%Token{} = t, tid, id) do
    case post(t, tid, "/Quotes/#{id}/Email", %{}) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  def history(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Quotes/#{id}/History"))

  def add_note(%Token{} = t, tid, id, note) do
    ok_body(put(t, tid, "/Quotes/#{id}/History", %{"HistoryRecords" => [%{"Details" => note}]}))
  end

  def attachments(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/Quotes/#{id}/Attachments"))

  def upload_attachment(%Token{} = t, tid, id, filename, content, content_type) do
    ok_body(
      Client.post(
        url("/Quotes/#{id}/Attachments/#{filename}"),
        content,
        t,
        [{"content-type", content_type}],
        tenant_id: tid
      )
    )
  end
end

defmodule Xero.Accounting.Items do
  @moduledoc "Xero Accounting API – Items (inventory). Tracked items: qty managed via transactions only."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    params = %{"where" => opts[:where], "order" => opts[:order]}

    case opts[:if_modified_since] do
      nil -> ok_body(req_get(t, tid, "/Items", params))
      since -> ok_body(req_get_modified(t, tid, "/Items", since, params))
    end
  end

  def get(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Items/#{id}"))
  def create(%Token{} = t, tid, attrs), do: ok_body(put(t, tid, "/Items", %{"Items" => [attrs]}))

  def update(%Token{} = t, tid, id, attrs) do
    ok_body(post(t, tid, "/Items/#{id}", %{"Items" => [Map.put(attrs, "ItemID", id)]}))
  end

  def delete(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/Items/#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  def history(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Items/#{id}/History"))
end

defmodule Xero.Accounting.TaxRates do
  @moduledoc "Xero Accounting API – Tax Rates."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/TaxRates", %{
        "where" => opts[:where],
        "order" => opts[:order],
        "TaxType" => opts[:tax_type]
      })
    )
  end

  def create(%Token{} = t, tid, attrs),
    do: ok_body(put(t, tid, "/TaxRates", %{"TaxRates" => [attrs]}))

  def update(%Token{} = t, tid, attrs),
    do: ok_body(post(t, tid, "/TaxRates", %{"TaxRates" => [attrs]}))

  def delete(%Token{} = t, tid, tax_type) do
    case req_delete(t, tid, "/TaxRates/#{tax_type}") do
      {:ok, _} -> :ok
      err -> err
    end
  end
end

defmodule Xero.Accounting.TrackingCategories do
  @moduledoc "Xero Accounting API – Tracking Categories and Options."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/TrackingCategories", %{
        "where" => opts[:where],
        "includeArchived" => opts[:include_archived]
      })
    )
  end

  def get(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/TrackingCategories/#{id}"))

  def create(%Token{} = t, tid, attrs) do
    ok_body(put(t, tid, "/TrackingCategories", %{"TrackingCategories" => [attrs]}))
  end

  def update(%Token{} = t, tid, id, attrs),
    do: ok_body(post(t, tid, "/TrackingCategories/#{id}", attrs))

  def archive(%Token{} = t, tid, id), do: update(t, tid, id, %{"Status" => "ARCHIVED"})

  def delete(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/TrackingCategories/#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  def create_option(%Token{} = t, tid, cat_id, name) do
    ok_body(
      put(t, tid, "/TrackingCategories/#{cat_id}/Options", %{
        "TrackingOptions" => [%{"Name" => name}]
      })
    )
  end

  def update_option(%Token{} = t, tid, cat_id, opt_id, name) do
    ok_body(post(t, tid, "/TrackingCategories/#{cat_id}/Options/#{opt_id}", %{"Name" => name}))
  end

  def delete_option(%Token{} = t, tid, cat_id, opt_id) do
    case req_delete(t, tid, "/TrackingCategories/#{cat_id}/Options/#{opt_id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end
end

defmodule Xero.Accounting.ContactGroups do
  @moduledoc "Xero Accounting API – Contact Groups."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/ContactGroups", %{"where" => opts[:where], "order" => opts[:order]})
    )
  end

  def get(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/ContactGroups/#{id}"))

  def create(%Token{} = t, tid, attrs),
    do: ok_body(put(t, tid, "/ContactGroups", %{"ContactGroups" => [attrs]}))

  def update(%Token{} = t, tid, id, attrs) do
    ok_body(post(t, tid, "/ContactGroups/#{id}", %{"ContactGroups" => [attrs]}))
  end

  def add_contacts(%Token{} = t, tid, group_id, contact_ids) do
    contacts = Enum.map(contact_ids, &%{"ContactID" => &1})
    ok_body(put(t, tid, "/ContactGroups/#{group_id}/Contacts", %{"Contacts" => contacts}))
  end

  def remove_contact(%Token{} = t, tid, group_id, contact_id) do
    case req_delete(t, tid, "/ContactGroups/#{group_id}/Contacts/#{contact_id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  def remove_all_contacts(%Token{} = t, tid, group_id) do
    case req_delete(t, tid, "/ContactGroups/#{group_id}/Contacts") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  def delete(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/ContactGroups/#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end
end

defmodule Xero.Accounting.Currencies do
  @moduledoc "Xero Accounting API – Currencies."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    ok_body(req_get(t, tid, "/Currencies", %{"where" => opts[:where], "order" => opts[:order]}))
  end

  def create(%Token{} = t, tid, attrs),
    do: ok_body(put(t, tid, "/Currencies", %{"Currencies" => [attrs]}))
end

defmodule Xero.Accounting.RepeatingInvoices do
  @moduledoc "Xero Accounting API – Repeating Invoices."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/RepeatingInvoices", %{"where" => opts[:where], "order" => opts[:order]})
    )
  end

  def get(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/RepeatingInvoices/#{id}"))

  def create(%Token{} = t, tid, attrs) do
    ok_body(put(t, tid, "/RepeatingInvoices", %{"RepeatingInvoices" => List.wrap(attrs)}))
  end

  def update(%Token{} = t, tid, id, attrs) do
    ok_body(
      post(t, tid, "/RepeatingInvoices/#{id}", %{
        "RepeatingInvoices" => [Map.put(attrs, "RepeatingInvoiceID", id)]
      })
    )
  end

  def delete(%Token{} = t, tid, id), do: update(t, tid, id, %{"Status" => "DELETED"})

  def history(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/RepeatingInvoices/#{id}/History"))

  def attachments(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/RepeatingInvoices/#{id}/Attachments"))

  def upload_attachment(%Token{} = t, tid, id, filename, content, content_type) do
    ok_body(
      Client.post(
        url("/RepeatingInvoices/#{id}/Attachments/#{filename}"),
        content,
        t,
        [{"content-type", content_type}],
        tenant_id: tid
      )
    )
  end
end

defmodule Xero.Accounting.ManualJournals do
  @moduledoc "Xero Accounting API – Manual Journals."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    params = %{"page" => opts[:page], "where" => opts[:where], "order" => opts[:order]}

    case opts[:if_modified_since] do
      nil -> ok_body(req_get(t, tid, "/ManualJournals", params))
      since -> ok_body(req_get_modified(t, tid, "/ManualJournals", since, params))
    end
  end

  def get(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/ManualJournals/#{id}"))

  def create(%Token{} = t, tid, attrs) do
    ok_body(put(t, tid, "/ManualJournals", %{"ManualJournals" => List.wrap(attrs)}))
  end

  def update(%Token{} = t, tid, id, attrs) do
    ok_body(
      post(t, tid, "/ManualJournals/#{id}", %{
        "ManualJournals" => [Map.put(attrs, "ManualJournalID", id)]
      })
    )
  end

  def void(%Token{} = t, tid, id), do: update(t, tid, id, %{"Status" => "VOIDED"})
  def delete(%Token{} = t, tid, id), do: update(t, tid, id, %{"Status" => "DELETED"})

  def history(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/ManualJournals/#{id}/History"))

  def attachments(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/ManualJournals/#{id}/Attachments"))

  def upload_attachment(%Token{} = t, tid, id, filename, content, content_type) do
    ok_body(
      Client.post(
        url("/ManualJournals/#{id}/Attachments/#{filename}"),
        content,
        t,
        [{"content-type", content_type}],
        tenant_id: tid
      )
    )
  end

  def stream(%Token{} = t, tid, opts \\ []) do
    Paginator.stream(fn page_opts ->
      case list(t, tid, Keyword.merge(opts, page_opts)) do
        {:ok, %{"ManualJournals" => items}} -> {:ok, items}
        other -> other
      end
    end)
  end
end

defmodule Xero.Accounting.LinkedTransactions do
  @moduledoc "Xero Accounting API – Linked Transactions (billable expenses)."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    params = %{
      "page" => opts[:page],
      "SourceTransactionID" => opts[:source_transaction_id],
      "ContactID" => opts[:contact_id],
      "Status" => opts[:status],
      "TargetTransactionID" => opts[:target_transaction_id]
    }

    ok_body(req_get(t, tid, "/LinkedTransactions", params))
  end

  def get(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/LinkedTransactions/#{id}"))

  def create(%Token{} = t, tid, attrs) do
    ok_body(put(t, tid, "/LinkedTransactions", %{"LinkedTransactions" => [attrs]}))
  end

  def update(%Token{} = t, tid, id, attrs) do
    ok_body(post(t, tid, "/LinkedTransactions/#{id}", %{"LinkedTransactions" => [attrs]}))
  end

  def delete(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/LinkedTransactions/#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end
end

defmodule Xero.Accounting.Journals do
  @moduledoc "Xero Accounting API – Journals (read-only). Requires accounting.journals.read scope."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    params = %{"offset" => opts[:offset], "paymentsOnly" => opts[:payments_only]}

    case opts[:if_modified_since] do
      nil -> ok_body(req_get(t, tid, "/Journals", params))
      since -> ok_body(req_get_modified(t, tid, "/Journals", since, params))
    end
  end

  def get(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Journals/#{id}"))
end

defmodule Xero.Accounting.Organisation do
  @moduledoc "Xero Accounting API – Organisation details."
  use Xero.API.Base, api: :accounting

  def get(%Token{} = t, tid), do: ok_body(req_get(t, tid, "/Organisation"))
  def actions(%Token{} = t, tid), do: ok_body(req_get(t, tid, "/Organisation/Actions"))
  def cis_settings(%Token{} = t, tid), do: ok_body(req_get(t, tid, "/Organisation/CISSettings"))
end

defmodule Xero.Accounting.Users do
  @moduledoc "Xero Accounting API – Users."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    params = %{"where" => opts[:where], "order" => opts[:order]}

    case opts[:if_modified_since] do
      nil -> ok_body(req_get(t, tid, "/Users", params))
      since -> ok_body(req_get_modified(t, tid, "/Users", since, params))
    end
  end

  def get(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Users/#{id}"))
end

defmodule Xero.Accounting.BrandingThemes do
  @moduledoc "Xero Accounting API – Branding Themes."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid), do: ok_body(req_get(t, tid, "/BrandingThemes"))
  def get(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/BrandingThemes/#{id}"))

  def payment_services(%Token{} = t, tid, id),
    do: ok_body(req_get(t, tid, "/BrandingThemes/#{id}/PaymentServices"))

  def create_payment_service(%Token{} = t, tid, id, attrs) do
    ok_body(
      post(t, tid, "/BrandingThemes/#{id}/PaymentServices", %{"PaymentServices" => [attrs]})
    )
  end
end

defmodule Xero.Accounting.Budgets do
  @moduledoc "Xero Accounting API – Budgets. Requires accounting.budgets.read scope."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Budgets", %{"DateFrom" => opts[:date_from], "DateTo" => opts[:date_to]})
    )
  end

  def get(%Token{} = t, tid, id, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Budgets/#{id}", %{
        "DateFrom" => opts[:date_from],
        "DateTo" => opts[:date_to]
      })
    )
  end
end

defmodule Xero.Accounting.InvoiceReminders do
  @moduledoc "Xero Accounting API – Invoice Reminder settings."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid), do: ok_body(req_get(t, tid, "/InvoiceReminders/Settings"))

  def update(%Token{} = t, tid, attrs),
    do: ok_body(post(t, tid, "/InvoiceReminders/Settings", attrs))
end

defmodule Xero.Accounting.PaymentServices do
  @moduledoc "Xero Accounting API – Payment Services. Requires paymentservices scope."
  use Xero.API.Base, api: :accounting

  def list(%Token{} = t, tid), do: ok_body(req_get(t, tid, "/PaymentServices"))
  def get(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/PaymentServices/#{id}"))

  def create(%Token{} = t, tid, attrs),
    do: ok_body(put(t, tid, "/PaymentServices", %{"PaymentServices" => [attrs]}))

  def delete(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/PaymentServices/#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end
end

defmodule Xero.Accounting.History do
  @moduledoc """
  Xero Accounting API – History & Notes.
  Add notes and retrieve audit history for: Accounts, BankTransactions, BankTransfers,
  Contacts, CreditNotes, Invoices, Items, ManualJournals, Overpayments,
  Payments, Prepayments, PurchaseOrders, Quotes, Receipts.
  """
  use Xero.API.Base, api: :accounting

  @valid ~w(Accounts BankTransactions BankTransfers Contacts CreditNotes
            Invoices Items ManualJournals Overpayments Payments Prepayments
            PurchaseOrders Quotes Receipts)

  def valid_resource_types, do: @valid

  def get(%Token{} = t, tid, resource, id) when resource in @valid,
    do: ok_body(req_get(t, tid, "/#{resource}/#{id}/History"))

  def get(_, _, r, _) do
    {:error,
     Error.config_error("Invalid resource: #{r}. Must be one of: #{Enum.join(@valid, ", ")}")}
  end

  def add_note(%Token{} = t, tid, resource, id, note) when resource in @valid,
    do:
      ok_body(
        put(t, tid, "/#{resource}/#{id}/History", %{"HistoryRecords" => [%{"Details" => note}]})
      )

  def add_note(_, _, r, _, _), do: {:error, Error.config_error("Invalid resource: #{r}")}
end
