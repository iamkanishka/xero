defmodule Xero.TypesTest do
  @moduledoc false

  use ExUnit.Case, async: true
  alias Xero.Types

  describe "invoice types and statuses" do
    test "invoice_types/0 contains ACCREC and ACCPAY" do
      types = Types.invoice_types()
      assert "ACCREC" in types
      assert "ACCPAY" in types
      assert length(types) == 2
    end

    test "invoice_statuses/0 contains all 6 documented statuses" do
      statuses = Types.invoice_statuses()
      assert "DRAFT" in statuses
      assert "SUBMITTED" in statuses
      assert "DELETED" in statuses
      assert "AUTHORISED" in statuses
      assert "PAID" in statuses
      assert "VOIDED" in statuses
      assert length(statuses) == 6
    end

    test "valid_invoice_status?/1 returns true for valid statuses" do
      Enum.each(Types.invoice_statuses(), fn s ->
        assert Types.valid_invoice_status?(s), "Expected #{s} to be valid"
      end)
    end

    test "valid_invoice_status?/1 returns false for invalid statuses" do
      assert Types.valid_invoice_status?("PENDING") == false
      assert Types.valid_invoice_status?("") == false
      assert Types.valid_invoice_status?("authorised") == false
      assert Types.valid_invoice_status?("CANCELLED") == false
    end
  end

  describe "account types" do
    test "account_types/0 contains all core types" do
      types = Types.account_types()
      assert "BANK" in types
      assert "SALES" in types
      assert "EXPENSE" in types
      assert "EQUITY" in types
      assert length(types) >= 20
    end

    test "valid_account_type?/1 works correctly" do
      assert Types.valid_account_type?("BANK") == true
      assert Types.valid_account_type?("INVALID") == false
    end

    test "account_classes/0 covers 5 classes" do
      classes = Types.account_classes()
      assert "ASSET" in classes
      assert "LIABILITY" in classes
      assert "REVENUE" in classes
      assert "EXPENSE" in classes
      assert "EQUITY" in classes
      assert length(classes) == 5
    end
  end

  describe "contact types" do
    test "contact_statuses/0 includes GDPRREQUEST" do
      assert "GDPRREQUEST" in Types.contact_statuses()
      assert "ACTIVE" in Types.contact_statuses()
      assert "ARCHIVED" in Types.contact_statuses()
    end

    test "phone_types/0 includes all 4 types" do
      types = Types.phone_types()
      assert "DEFAULT" in types
      assert "MOBILE" in types
      assert "FAX" in types
      assert "DDI" in types
    end
  end

  describe "payment types" do
    test "payment_types/0 has 8 types" do
      assert length(Types.payment_types()) == 8
    end

    test "payment_statuses/0 has AUTHORISED and DELETED" do
      assert "AUTHORISED" in Types.payment_statuses()
      assert "DELETED" in Types.payment_statuses()
    end
  end

  describe "tax_types_for_region/1" do
    test ":au returns AU-specific tax types" do
      types = Types.tax_types_for_region(:au)
      assert "OUTPUT" in types
      assert "INPUT" in types
      assert "GSTONIMPORTS" in types
      assert length(types) >= 10
    end

    test ":nz returns NZ-specific types including ZERORATED" do
      types = Types.tax_types_for_region(:nz)
      assert "ZERORATED" in types
      assert "OUTPUT2" in types
    end

    test ":uk returns UK-specific types including reverse charge" do
      types = Types.tax_types_for_region(:uk)
      assert "REVERSECHARGEOUTPUT2" in types
      assert "REVERSECHARGEOUTPUTSERVICES2" in types
      assert "ECACQUISITIONS2" in types
    end

    test ":us returns US tax types" do
      types = Types.tax_types_for_region(:us)
      assert "TAX" in types
      assert "EXEMPTOUTPUT" in types
    end

    test "unknown region returns empty list" do
      assert Types.tax_types_for_region(:ca) == []
      assert Types.tax_types_for_region(:xx) == []
    end
  end

  describe "bank transaction types" do
    test "bank_transaction_types/0 covers all variants" do
      types = Types.bank_transaction_types()
      assert "SPEND" in types
      assert "RECEIVE" in types
      assert "SPEND-OVERPAYMENT" in types
      assert "RECEIVE-TRANSFER" in types
      assert length(types) >= 8
    end
  end

  describe "purchase order and quote statuses" do
    test "purchase_order_statuses/0 includes BILLED" do
      assert "BILLED" in Types.purchase_order_statuses()
      assert "AUTHORISED" in Types.purchase_order_statuses()
    end

    test "quote_statuses/0 includes ACCEPTED and INVOICED" do
      assert "ACCEPTED" in Types.quote_statuses()
      assert "INVOICED" in Types.quote_statuses()
    end
  end

  describe "journal source types" do
    test "journal_source_types/0 has many source types" do
      types = Types.journal_source_types()
      assert "ACCREC" in types
      assert "MANJOURNAL" in types
      assert "PAYSLIP" in types
      assert length(types) >= 15
    end
  end

  describe "line_amount_types/0" do
    test "includes Exclusive, Inclusive, NoTax" do
      types = Types.line_amount_types()
      assert "Exclusive" in types
      assert "Inclusive" in types
      assert "NoTax" in types
    end
  end
end
