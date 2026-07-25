import Config

config :xero,
  client_id: "test-client-id",
  client_secret: "test-client-secret",
  redirect_uri: "https://localhost/callback",
  scopes: ~w(openid accounting.transactions),
  timeout: 5_000,
  connect_timeout: 2_000,
  pool_size: 2,
  pool_count: 1,
  log_level: :none
