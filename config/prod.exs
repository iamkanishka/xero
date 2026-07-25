import Config

config :xero,
  client_id: System.fetch_env!("XERO_CLIENT_ID"),
  client_secret: System.fetch_env!("XERO_CLIENT_SECRET"),
  redirect_uri: System.fetch_env!("XERO_REDIRECT_URI"),
  log_level: :warning
