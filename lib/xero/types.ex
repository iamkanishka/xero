defmodule Xero.Types do
  @moduledoc """
  Xero API type constants, status codes, and helper functions.

  Covers all enumerations referenced in the Xero API documentation
  for all 13 APIs (Accounting, Assets, Bank Feeds, Files, Finance,
  Projects, Payroll AU/NZ/UK, Practice Manager, App Store, eInvoicing).

  ## Usage

      Xero.Types.invoice_statuses()
      #=> ["DRAFT", "SUBMITTED", "DELETED", "AUTHORISED", "PAID", "VOIDED"]

      Xero.Types.valid_invoice_status?("AUTHORISED")
      #=> true

      Xero.Types.tax_types_for_region(:au)
      #=> ["OUTPUT", "INPUT", ...]
  """

  # ─── Account ─────────────────────────────────────────────────────────────────

  @account_classes ~w(ASSET EQUITY EXPENSE LIABILITY REVENUE)
  @account_types ~w(BANK CURRENT CURRLIAB DEPRECIATN DIRECTCOSTS EQUITY EXPENSE FIXED
                        INVENTORY LIABILITY NONCURRENT OTHERINCOME OVERHEADS PREPAYMENT
                        REVENUE SALES TERMLIAB PAYGLIABILITY SUPERANNUATIONEXPENSE
                        SUPERANNUATIONLIABILITY WAGESEXPENSE WAGESPAYABLELIABILITY)
  @account_statuses ~w(ACTIVE ARCHIVED DELETED)
  @bank_account_types ~w(BANK CREDITCARD PAYPAL NONE)
  @system_accounts ~w(DEBTORS CREDITORS BANKCURRENCYGAIN GSTONCAPIMPORTS GSTONIMPORTS
                        HISTORICAL REALISEDCURRENCYGAIN RETAINEDEARNINGS ROUNDING
                        TRACKINGTRANSFERS UNPAIDEXPCLM UNREALISEDCURRENCYGAIN WAGEPAYABLES)

  def account_classes, do: @account_classes
  def account_types, do: @account_types
  def account_statuses, do: @account_statuses
  def bank_account_types, do: @bank_account_types
  def system_accounts, do: @system_accounts

  # ─── Invoice ─────────────────────────────────────────────────────────────────

  @invoice_types ~w(ACCREC ACCPAY)
  @invoice_statuses ~w(DRAFT SUBMITTED DELETED AUTHORISED PAID VOIDED)
  @line_amount_types ~w(Exclusive Inclusive NoTax)

  def invoice_types, do: @invoice_types
  def invoice_statuses, do: @invoice_statuses
  def line_amount_types, do: @line_amount_types

  # ─── Credit Note ─────────────────────────────────────────────────────────────

  @credit_note_types ~w(ACCRECCREDIT ACCPAYCREDIT)
  @credit_note_statuses ~w(DRAFT SUBMITTED DELETED AUTHORISED PAID VOIDED)

  def credit_note_types, do: @credit_note_types
  def credit_note_statuses, do: @credit_note_statuses

  # ─── Bank Transaction ─────────────────────────────────────────────────────────

  @bank_transaction_types ~w(RECEIVE RECEIVE-OVERPAYMENT RECEIVE-PREPAYMENT
    SPEND SPEND-OVERPAYMENT SPEND-PREPAYMENT RECEIVE-TRANSFER SPEND-TRANSFER
    RECEIVE-CREDIT SPEND-CREDIT)
  @bank_transaction_statuses ~w(AUTHORISED DELETED)

  def bank_transaction_types, do: @bank_transaction_types
  def bank_transaction_statuses, do: @bank_transaction_statuses

  # ─── Contact ─────────────────────────────────────────────────────────────────

  @contact_statuses ~w(ACTIVE ARCHIVED GDPRREQUEST)
  @address_types ~w(POBOX STREET DELIVERY)
  @phone_types ~w(DEFAULT DDI MOBILE FAX)

  def contact_statuses, do: @contact_statuses
  def address_types, do: @address_types
  def phone_types, do: @phone_types

  # ─── Payment ─────────────────────────────────────────────────────────────────

  @payment_types ~w(ACCRECPAYMENT ACCPAYPAYMENT ARCREDITPAYMENT APCREDITPAYMENT
    AROVERPAYMENTPAYMENT APOVERPAYMENTPAYMENT ARPREPAYMENTPAYMENT APPREPAYMENTPAYMENT)
  @payment_statuses ~w(AUTHORISED DELETED)
  @payment_terms ~w(DAYSAFTERBILLDATE DAYSAFTERBILLMONTH OFCURRENTMONTH OFFOLLOWINGMONTH)
  @payment_term_types ~w(DAYSAFTERBILLDATE DAYSAFTERBILLMONTH OFCURRENTMONTH OFFOLLOWINGMONTH)

  def payment_types, do: @payment_types
  def payment_statuses, do: @payment_statuses
  def payment_terms, do: @payment_terms
  def payment_term_types, do: @payment_term_types

  # ─── Purchase Order ───────────────────────────────────────────────────────────

  @purchase_order_statuses ~w(DRAFT SUBMITTED AUTHORISED BILLED DELETED)

  def purchase_order_statuses, do: @purchase_order_statuses

  # ─── Quote ───────────────────────────────────────────────────────────────────

  @quote_statuses ~w(DRAFT SENT DECLINED ACCEPTED INVOICED DELETED)

  def quote_statuses, do: @quote_statuses

  # ─── Organisation ─────────────────────────────────────────────────────────────

  @organisation_types ~w(COMPANY CHARITY CLUBSOCIETY PARTNERSHIP PRACTICE
                                 SELFEMPLOYED SOLE TRUST)
  @organisation_version_types ~w(AU NZ GLOBAL UK US DEMO COMPANY PARTNER)
  @organisation_class_types ~w(DEMO STARTER STANDARD PREMIUM PREMIUM_20 PREMIUM_50
                                 PREMIUM_100 LEDGER GST_CASHBOOK CASHBOOK)

  def organisation_types, do: @organisation_types
  def organisation_version_types, do: @organisation_version_types
  def organisation_class_types, do: @organisation_class_types

  # ─── Manual Journal ───────────────────────────────────────────────────────────

  @manual_journal_statuses ~w(DRAFT POSTED DELETED VOIDED)

  def manual_journal_statuses, do: @manual_journal_statuses

  # ─── Linked Transaction ──────────────────────────────────────────────────────

  @linked_transaction_statuses ~w(APPROVED DRAFT ONDRAFT BILLED VOIDED)
  @linked_transaction_types ~w(BILLABLEEXPENSE)
  @linked_transaction_source_types ~w(BANKTRANSACTION CREDITNOTE INVOICE
                                      MANUALJOURNALLINE PAYMENT)

  def linked_transaction_statuses, do: @linked_transaction_statuses
  def linked_transaction_types, do: @linked_transaction_types
  def linked_transaction_source_types, do: @linked_transaction_source_types

  # ─── Journal Source ───────────────────────────────────────────────────────────

  @journal_source_types ~w(ACCREC ACCPAY ACCRECCREDIT ACCPAYCREDIT ACCRECPAYMENT ACCPAYPAYMENT
    ARCREDITPAYMENT APCREDITPAYMENT CASHREC CASHPAID TRANSFER ARPREPAYMENT APPREPAYMENT
    AROVERPAYMENT APOVERPAYMENT EXPCLAIM EXPPAYMENT MANJOURNAL PAYSLIP WAGEPAYABLE
    INTEGRATEDPAYROLLEXPENSE INTEGRATEDPAYROLLLIABILITY INTEGRATEDPAYROLLWORKERSCOMP
    EXTERNALSPENDMONEY EXTERNALRECEIVEMONEY)

  def journal_source_types, do: @journal_source_types

  # ─── Over/Prepayment ─────────────────────────────────────────────────────────

  @overpayment_types ~w(RECEIVE-OVERPAYMENT AROVERPAYMENT SPEND-OVERPAYMENT APOVERPAYMENT)
  @prepayment_types ~w(RECEIVE-PREPAYMENT ARPREPAYMENT SPEND-PREPAYMENT APPREPAYMENT)

  def overpayment_types, do: @overpayment_types
  def prepayment_types, do: @prepayment_types

  # ─── Tax Types ───────────────────────────────────────────────────────────────

  @tax_types_au ~w(OUTPUT INPUT CAPEXINPUT EXEMPTEXPORT EXEMPTEXPENSES EXEMPTCAPITAL
    EXEMPTOUTPUT INPUTTAXED BASEXCLUDED GSTONCAPIMPORTS GSTONIMPORTS NONE)

  @tax_types_nz ~w(OUTPUT2 INPUT2 CAPEXINPUT2 EXEMPTEXPORT EXEMPTEXPENSES EXEMPTCAPITAL
    EXEMPTOUTPUT2 INPUTTAXED BASEXCLUDED ZERORATED NONE)

  @tax_types_uk ~w(OUTPUT2 INPUT2 CAPEXINPUT2 EXEMPTEXPORT EXEMPTEXPENSES EXEMPTCAPITAL
    EXEMPTOUTPUT2 INPUTTAXED BASEXCLUDED REVERSECHARGEOUTPUT2 REVERSECHARGEOUTPUTSERVICES2
    ECACQUISITIONS2 DRCR NONE)

  @tax_types_us ~w(TAX EXEMPTEXPENSES EXEMPTOUTPUT NONE)

  def tax_types_au, do: @tax_types_au
  def tax_types_nz, do: @tax_types_nz
  def tax_types_uk, do: @tax_types_uk
  def tax_types_us, do: @tax_types_us

  @doc "Returns tax types for the given region atom (`:au` | `:nz` | `:uk` | `:us`)."
  @spec tax_types_for_region(atom()) :: list(String.t())
  def tax_types_for_region(:au), do: @tax_types_au
  def tax_types_for_region(:nz), do: @tax_types_nz
  def tax_types_for_region(:uk), do: @tax_types_uk
  def tax_types_for_region(:us), do: @tax_types_us
  def tax_types_for_region(_), do: []

  # ─── Assets ──────────────────────────────────────────────────────────────────

  @asset_statuses ~w(DRAFT REGISTERED DISPOSED)
  @depreciation_methods ~w(NoDepreciation StraightLine DiminishingValue100
                             DiminishingValue150 DiminishingValue200 FullDepreciation)
  @averaging_methods ~w(ActualDays FullMonth)
  @disposal_types ~w(SOLD SCRAPPED WRITTEN_OFF)
  @depreciation_calc_methods ~w(None Rate Life)

  def asset_statuses, do: @asset_statuses
  def depreciation_methods, do: @depreciation_methods
  def averaging_methods, do: @averaging_methods
  def disposal_types, do: @disposal_types
  def depreciation_calc_methods, do: @depreciation_calc_methods

  # ─── Projects ────────────────────────────────────────────────────────────────

  @project_statuses ~w(INPROGRESS CLOSED CANCELLED)
  @task_charge_types ~w(TIME FIXED NON_CHARGEABLE)

  def project_statuses, do: @project_statuses
  def task_charge_types, do: @task_charge_types

  # ─── eInvoicing ──────────────────────────────────────────────────────────────

  @einvoicing_document_statuses ~w(SENT DELIVERED FAILED REJECTED)
  @einvoicing_directions ~w(SENT RECEIVED)

  def einvoicing_document_statuses, do: @einvoicing_document_statuses
  def einvoicing_directions, do: @einvoicing_directions

  # ─── App Store ───────────────────────────────────────────────────────────────

  @subscription_statuses ~w(ACTIVE CANCELED TRIALING PAST_DUE INCOMPLETE INCOMPLETE_EXPIRED)

  def subscription_statuses, do: @subscription_statuses

  # ─── Payroll (shared) ────────────────────────────────────────────────────────

  @payrun_statuses ~w(DRAFT POSTED PAYCHEQUES_CREATED)
  @timesheet_statuses ~w(DRAFT APPROVED PROCESSED)
  @employment_types ~w(EMPLOYEE CONTRACTOR)

  def payrun_statuses, do: @payrun_statuses
  def timesheet_statuses, do: @timesheet_statuses
  def employment_types, do: @employment_types

  # ─── Practice Manager ────────────────────────────────────────────────────────

  @pm_job_statuses ~w(Prospect NotStarted InProgress Overdue Completed Cancelled)
  @pm_job_priorities ~w(Low Normal High)

  def pm_job_statuses, do: @pm_job_statuses
  def pm_job_priorities, do: @pm_job_priorities

  # ─── Bank Feeds ──────────────────────────────────────────────────────────────

  @feed_account_types ~w(BANK CREDITCARD)
  @credit_debit_indicators ~w(CREDIT DEBIT)

  def feed_account_types, do: @feed_account_types
  def credit_debit_indicators, do: @credit_debit_indicators

  # ─── Validators ──────────────────────────────────────────────────────────────

  @doc "Returns `true` if the string is a valid Xero invoice status."
  @spec valid_invoice_status?(String.t()) :: boolean()
  def valid_invoice_status?(s), do: s in @invoice_statuses

  @doc "Returns `true` if the string is a valid Xero account type."
  @spec valid_account_type?(String.t()) :: boolean()
  def valid_account_type?(t), do: t in @account_types

  @doc "Returns `true` if the string is a valid Xero contact status."
  @spec valid_contact_status?(String.t()) :: boolean()
  def valid_contact_status?(s), do: s in @contact_statuses

  @doc "Returns `true` if the string is a valid Xero quote status."
  @spec valid_quote_status?(String.t()) :: boolean()
  def valid_quote_status?(s), do: s in @quote_statuses

  @doc "Returns `true` if the string is a valid Xero purchase order status."
  @spec valid_purchase_order_status?(String.t()) :: boolean()
  def valid_purchase_order_status?(s), do: s in @purchase_order_statuses

  @doc "Returns `true` if the string is a valid Xero asset status."
  @spec valid_asset_status?(String.t()) :: boolean()
  def valid_asset_status?(s), do: s in @asset_statuses

  @doc "Returns `true` if the string is a valid depreciation method."
  @spec valid_depreciation_method?(String.t()) :: boolean()
  def valid_depreciation_method?(m), do: m in @depreciation_methods

  @doc "Returns `true` if the string is a valid project status."
  @spec valid_project_status?(String.t()) :: boolean()
  def valid_project_status?(s), do: s in @project_statuses
end
