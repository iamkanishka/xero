defmodule Xero.Error do
  @moduledoc """
  Structured error type returned by all Xero API operations.

  All public functions return `{:ok, result}` or `{:error, Xero.Error.t()}`.

  ## Error Types

  | `:type` | HTTP | Description |
  |---------|------|-------------|
  | `:unauthorized` | 401 | Invalid/expired access token |
  | `:forbidden` | 403 | Insufficient scope or permissions |
  | `:not_found` | 404 | Resource does not exist |
  | `:unprocessable` | 422 | Validation error |
  | `:rate_limited` | 429 | Rate limit exceeded |
  | `:server_error` | 5xx | Xero server error |
  | `:network_error` | — | Connection/timeout failure |
  | `:config_error` | — | Invalid library usage |
  | `:oauth_error` | — | OAuth token endpoint failure |
  """

  @type error_type ::
          :unauthorized
          | :forbidden
          | :not_found
          | :unprocessable
          | :rate_limited
          | :server_error
          | :network_error
          | :config_error
          | :oauth_error
          | :unknown

  @type t :: %__MODULE__{
          type: error_type(),
          message: String.t(),
          detail: term(),
          status: pos_integer() | nil,
          retry_after: pos_integer() | nil,
          request_id: String.t() | nil,
          raw: term()
        }

  defexception [:type, :message, :detail, :status, :retry_after, :request_id, :raw]

  @impl true
  def message(%__MODULE__{message: msg, type: type, status: status}) do
    "[Xero][#{type}]#{if status, do: " HTTP #{status}:"} #{msg}"
  end

  @spec from_response(map()) :: t()
  def from_response(%{status: 401} = r),
    do: %__MODULE__{
      type: :unauthorized,
      status: 401,
      message: "Unauthorized — check access token",
      raw: r.body,
      request_id: req_id(r)
    }

  def from_response(%{status: 403} = r),
    do: %__MODULE__{
      type: :forbidden,
      status: 403,
      message: "Forbidden — insufficient scope",
      detail: parse_body(r.body),
      raw: r.body,
      request_id: req_id(r)
    }

  def from_response(%{status: 404} = r),
    do: %__MODULE__{
      type: :not_found,
      status: 404,
      message: "Resource not found",
      raw: r.body,
      request_id: req_id(r)
    }

  def from_response(%{status: 422} = r) do
    detail = parse_body(r.body)

    %__MODULE__{
      type: :unprocessable,
      status: 422,
      detail: detail,
      raw: r.body,
      message: extract_msg(detail) || "Validation error",
      request_id: req_id(r)
    }
  end

  def from_response(%{status: 429} = r),
    do: %__MODULE__{
      type: :rate_limited,
      status: 429,
      message: "Rate limit exceeded",
      retry_after: parse_retry_after(r),
      raw: r.body,
      request_id: req_id(r)
    }

  def from_response(%{status: s} = r) when s >= 500,
    do: %__MODULE__{
      type: :server_error,
      status: s,
      message: "Xero server error",
      raw: r.body,
      request_id: req_id(r)
    }

  def from_response(r),
    do: %__MODULE__{type: :unknown, message: "Unexpected response", raw: r}

  @spec network_error(term()) :: t()
  def network_error(reason),
    do: %__MODULE__{
      type: :network_error,
      message: "Network error: #{inspect(reason)}",
      raw: reason
    }

  @spec config_error(String.t()) :: t()
  def config_error(msg), do: %__MODULE__{type: :config_error, message: msg}

  defp parse_retry_after(%{headers: headers}) do
    case List.keyfind(headers || [], "retry-after", 0) do
      {_, v} -> String.to_integer(v)
      nil -> 60
    end
  end

  defp req_id(%{headers: headers}) do
    case List.keyfind(headers || [], "x-correlation-id", 0) do
      {_, id} -> id
      nil -> nil
    end
  end

  defp parse_body(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, p} -> p
      _ -> body
    end
  end

  defp parse_body(body), do: body

  defp extract_msg(%{"Message" => m}), do: m
  defp extract_msg(%{"message" => m}), do: m
  defp extract_msg(_), do: nil
end
