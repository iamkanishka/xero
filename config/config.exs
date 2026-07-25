import Config

config :xero,
  client_id: System.get_env("XERO_CLIENT_ID", "dev-client-id"),
  client_secret: System.get_env("XERO_CLIENT_SECRET", "dev-client-secret"),
  redirect_uri: System.get_env("XERO_REDIRECT_URI", "http://localhost:4000/auth/xero/callback"),
  scopes: ~w(
    openid profile email offline_access
    accounting.transactions
    accounting.contacts
    accounting.settings
    accounting.reports.read
    accounting.journals.read
    accounting.attachments
    accounting.budgets.read
    assets
    files
    projects
  ),
  base_url: "https://api.xero.com",
  identity_url: "https://identity.xero.com",
  timeout: 30_000,
  connect_timeout: 10_000,
  pool_size: 10,
  pool_count: 4,
  max_retries: 3,
  retry_base_delay: 1_000,
  retry_max_delay: 30_000,
  log_level: :info

import_config "#{config_env()}.exs"
