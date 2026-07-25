defmodule Xero.Auth.Token do
  @moduledoc "Represents a Xero OAuth 2.0 token pair."

  @type t :: %__MODULE__{
          access_token: String.t(),
          refresh_token: String.t() | nil,
          expires_at: DateTime.t(),
          token_type: String.t(),
          id_token: String.t() | nil,
          scopes: list(String.t())
        }

  defstruct [
    :access_token,
    :refresh_token,
    :expires_at,
    :id_token,
    token_type: "Bearer",
    scopes: []
  ]

  @spec from_response(map()) :: t()
  def from_response(%{"access_token" => at} = resp) do
    %__MODULE__{
      access_token: at,
      refresh_token: resp["refresh_token"],
      expires_at: DateTime.add(DateTime.utc_now(), resp["expires_in"] || 1_800, :second),
      token_type: resp["token_type"] || "Bearer",
      id_token: resp["id_token"],
      scopes: parse_scopes(resp["scope"])
    }
  end

  @spec auth_header(t()) :: {String.t(), String.t()}
  def auth_header(%__MODULE__{access_token: t, token_type: type}),
    do: {"authorization", "#{type} #{t}"}

  defp parse_scopes(nil), do: []
  defp parse_scopes(s) when is_binary(s), do: String.split(s, " ")
  defp parse_scopes(l) when is_list(l), do: l
end
