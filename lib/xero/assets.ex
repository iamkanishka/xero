defmodule Xero.Assets do
  @moduledoc """
  Xero Assets API – Fixed asset lifecycle management.
  Base URL: `https://api.xero.com/assets.xro/1.0/`
  Scopes: `assets` or `assets.read`

  ## Status Flow

      DRAFT → REGISTERED → DISPOSED
      DRAFT → DISPOSED (direct)

  ## Depreciation Methods

  - `StraightLine` — equal annual charge
  - `DiminishingValue100` / `DiminishingValue150` / `DiminishingValue200`
  - `FullDepreciation` — 100% in year of purchase
  - `NoDepreciation`

  ## Averaging Methods

  - `ActualDays` — based on the number of days in the period
  - `FullMonth` — depreciation for the full month

  ## Examples

      {:ok, %{"items" => assets}} = Xero.Assets.list(token, tenant_id, status: "REGISTERED")

      {:ok, asset} = Xero.Assets.create(token, tenant_id, %{
        "assetName"    => "Office Laptop",
        "assetNumber"  => "LAPTOP-001",
        "purchaseDate" => "2024-01-15",
        "purchasePrice" => 1200.00,
        "assetStatus"  => "DRAFT",
        "bookDepreciationSetting" => %{
          "depreciationMethod"    => "StraightLine",
          "averagingMethod"       => "ActualDays",
          "depreciationRate"      => 0.25,
          "depreciationCalculationMethod" => "None"
        }
      })

      # Move from DRAFT → REGISTERED
      {:ok, _} = Xero.Assets.update(token, tenant_id, asset_id, %{"assetStatus" => "REGISTERED"})

      # Dispose of a registered asset
      {:ok, _} = Xero.Assets.dispose(token, tenant_id, asset_id, %{
        "disposalDate"   => "2024-06-30",
        "disposalPrice"  => 200.00,
        "disposalType"   => "SOLD"
      })
  """

  use Xero.API.Base, api: :assets

  @doc """
  Lists fixed assets.

  ## Options

  - `:status` — `"DRAFT"`, `"REGISTERED"`, or `"DISPOSED"`
  - `:page` — Page number (default 1)
  - `:page_size` — Items per page (max 100, default 10)
  - `:order_by` — Field to order by: `"AssetName"`, `"AssetNumber"`, `"AssetStatus"`,
    `"DepreciableAmount"`, `"TotalDepreciationAmount"`, `"BookValue"`
  - `:sort_direction` — `"ASC"` or `"DESC"`
  - `:filter_by` — Free-text search across name, number, serial number
  """
  @spec list(Token.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def list(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Assets", %{
        "status" => opts[:status],
        "page" => opts[:page],
        "pageSize" => opts[:page_size],
        "orderBy" => opts[:order_by],
        "sortDirection" => opts[:sort_direction],
        "filterBy" => opts[:filter_by]
      })
    )
  end

  @doc "Retrieves a single asset by ID."
  @spec get(Token.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(%Token{} = t, tid, id), do: ok_body(req_get(t, tid, "/Assets/#{id}"))

  @doc """
  Creates a new fixed asset. Assets start in `DRAFT` status.

  ## Required fields

  - `"assetName"` — Display name
  - `"assetStatus"` — `"DRAFT"` or `"REGISTERED"`
  - `"bookDepreciationSetting"` — Depreciation config map
  """
  @spec create(Token.t(), String.t(), map()) :: {:ok, map()} | {:error, Error.t()}
  def create(%Token{} = t, tid, attrs), do: ok_body(post(t, tid, "/Assets", attrs))

  @doc """
  Updates a DRAFT asset. Only DRAFT assets can be updated.
  To register an asset, update with `assetStatus: "REGISTERED"`.
  """
  @spec update(Token.t(), String.t(), String.t(), map()) :: {:ok, map()} | {:error, Error.t()}
  def update(%Token{} = t, tid, id, attrs), do: ok_body(put(t, tid, "/Assets/#{id}", attrs))

  @doc """
  Disposes of a REGISTERED asset.

  ## Required disposal fields

  - `"disposalDate"` — Date of disposal (YYYY-MM-DD)
  - `"disposalType"` — `"SOLD"`, `"SCRAPPED"`, or `"WRITTEN_OFF"`

  ## Optional fields

  - `"disposalPrice"` — Proceeds from sale (default 0)
  - `"disposalAccount"` — Account code for disposal proceeds
  """
  @spec dispose(Token.t(), String.t(), String.t(), map()) :: {:ok, map()} | {:error, Error.t()}
  def dispose(%Token{} = t, tid, id, disposal_attrs) do
    ok_body(post(t, tid, "/Assets/#{id}/Dispose", disposal_attrs))
  end

  @doc """
  Deletes a DRAFT asset. Only DRAFT assets can be deleted.
  REGISTERED assets must be disposed of instead.
  """
  @spec delete(Token.t(), String.t(), String.t()) :: :ok | {:error, Error.t()}
  def delete(%Token{} = t, tid, id) do
    case req_delete(t, tid, "/Assets/#{id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @doc "Returns asset settings (default depreciation accounts) for the organisation."
  @spec settings(Token.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def settings(%Token{} = t, tid), do: ok_body(req_get(t, tid, "/Settings"))

  @doc "Returns all asset types defined in the organisation."
  @spec asset_types(Token.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def asset_types(%Token{} = t, tid), do: ok_body(req_get(t, tid, "/AssetTypes"))

  @doc """
  Creates a new asset type.

  ## Required fields

  - `"assetTypeName"` — Display name for the type
  - `"fixedAssetAccountId"` — GL account for the asset value
  - `"depreciationExpenseAccountId"` — GL account for depreciation expense
  - `"accumulatedDepreciationAccountId"` — GL account for accumulated depreciation
  - `"bookDepreciationSetting"` — Default depreciation settings for this type
  """
  @spec create_asset_type(Token.t(), String.t(), map()) :: {:ok, map()} | {:error, Error.t()}
  def create_asset_type(%Token{} = t, tid, attrs), do: ok_body(post(t, tid, "/AssetTypes", attrs))

  @doc """
  Updates an existing asset type.
  """
  @spec update_asset_type(Token.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Error.t()}
  def update_asset_type(%Token{} = t, tid, id, attrs),
    do: ok_body(put(t, tid, "/AssetTypes/#{id}", attrs))

  @doc """
  Returns depreciation schedules for all registered assets.

  ## Options

  - `:book_effective_date_of_depreciation` — Date to calculate from (YYYY-MM-DD)
  """
  @spec depreciation_schedules(Token.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def depreciation_schedules(%Token{} = t, tid, opts \\ []) do
    ok_body(
      req_get(t, tid, "/Assets/Schedules", %{
        "bookEffectiveDateOfDepreciation" => opts[:book_effective_date_of_depreciation]
      })
    )
  end

  @doc """
  Runs depreciation for all assets up to a specific date.

  ## Required fields

  - `"depreciationDate"` — Run depreciation up to this date (YYYY-MM-DD)
  """
  @spec run_depreciation(Token.t(), String.t(), map()) :: {:ok, map()} | {:error, Error.t()}
  def run_depreciation(%Token{} = t, tid, attrs),
    do: ok_body(post(t, tid, "/Assets/Depreciation", attrs))
end
