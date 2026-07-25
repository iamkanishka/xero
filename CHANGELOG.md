# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-07-25

### Added

#### Core Infrastructure
- Xero.Application — OTP supervisor: Finch, TokenStore, RateLimiter, Telemetry
- Xero.Config — NimbleOptions-validated configuration with full documentation
- Xero.Error — Typed exception struct with 9 error categories and Exception behaviour
- Xero.Paginator — stream/2 (lazy), fetch_all/2, fetch_page/2 helpers
- Xero.Telemetry — Supervisor + default handler for 4 telemetry event types
- Xero.Types — All Xero status codes, enumerations, and regional tax types
- Xero.API.Base — __using__ macro providing get/put/post/delete/ok_body/url helpers

#### Auth
- Xero.Auth — Full OAuth 2.0 Authorization Code flow, Client Credentials, refresh, revocation
- Xero.Auth.Token — Token struct with from_response/1 and auth_header/1
- Xero.Auth.TokenStore — ETS GenServer with proactive 5-minute pre-expiry background refresh

#### HTTP
- Xero.HTTP.Client — Finch-backed client with auth injection, telemetry, retry on 429
- Xero.HTTP.RateLimiter — Per-tenant token bucket (60/min, 5 000/day) in ETS

#### Accounting API (30+ endpoints)
- Invoices — CRUD, email, PDF, online URL, stream, attachments, history
- Contacts — CRUD, stream, CIS (UK), history, attachments
- Accounts — CRUD, archive, delete
- Payments — Create, delete (void), history, stream
- Bank Transactions — CRUD, stream
- Bank Transfers — CRUD
- Batch Payments — Create, delete
- Credit Notes — CRUD, allocations
- Overpayments & Prepayments — Get, allocate
- Purchase Orders — CRUD, PDF, stream
- Quotes — CRUD
- Items — CRUD
- Manual Journals — CRUD, stream
- Journals — List, get (read-only)
- Linked Transactions — CRUD
- Tax Rates — List, create, update
- Tracking Categories — CRUD, options CRUD
- Contact Groups — CRUD, member management
- Currencies — List, create
- Repeating Invoices — List, get
- Organisation — Get, actions, CIS
- Users — List, get
- Branding Themes — List, get, payment services
- Budgets — List, get
- Invoice Reminders — List, update
- Payment Services — CRUD
- History & Notes — Get + add note for 14 resource types
- Reports — 11 built-in reports (Balance Sheet, P&L, Trial Balance, etc.)

#### Other APIs
- Xero.Assets — Fixed assets, depreciation schedules, asset types
- Xero.BankFeeds — Feed connections, statement pushing (requires partner approval)
- Xero.Files — Upload, download, folders, object associations
- Xero.Finance — Bank Statements Plus, Cash Validation, Financial Statements, Accounting Activity
- Xero.Projects — Projects, tasks, time entries, project items, users
- Xero.Payroll.AU — Employees, pay items, calendars, pay runs, payslips, timesheets, leave, superfunds
- Xero.Payroll.NZ — Employees, pay runs, payslips, leave types, statutory leave
- Xero.Payroll.UK — Employees, tax, NI, payment method, working patterns, pay runs, payslips, leave
- Xero.PracticeManager — Jobs (full lifecycle), clients, staff, time, tasks, categories, templates, invoices
- Xero.AppStore — Client Credentials token, subscriptions, metered billing
- Xero.EInvoicing — PEPPOL participant lookup, document send/receive/acknowledge, UBL XML download

#### Testing
- Xero.Test.Factory — Rich test data factories for all resource types
- Xero.Test.HTTPCase — Bypass-based ExUnit case template
- 8 test modules covering all core infrastructure with 60+ test cases

[Unreleased]: https://github.com/iamkanishka/xero/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/iamkanishka/xero/releases/tag/v1.0.0
