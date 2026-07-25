[
  # clean_params/1 (Xero.API.Runtime, delegated into every resource module via
  # Xero.API.Base) is intentionally broader than any single call site: it's
  # called with a different literal map shape from ~30 different modules.
  # Dialyzer reports contract_supertype against whichever call site it samples
  # first — narrowing the spec to match that one caller would just move the
  # same warning elsewhere, or worse, turn it into a real contract violation
  # for a caller with a different shape.
  {"lib/xero/accounting/invoices.ex", :contract_supertype}
]

