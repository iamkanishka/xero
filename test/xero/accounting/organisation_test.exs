defmodule Xero.Accounting.OrganisationTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.Accounting.Organisation

  describe "get/2" do
    test "returns organisation details", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/Organisation", 200, %{
        "Organisations" => [
          %{
            "OrganisationID" => "org-1",
            "Name" => "Test Company Ltd",
            "CountryCode" => "AU",
            "BaseCurrency" => "AUD",
            "OrganisationType" => "COMPANY"
          }
        ]
      })

      assert {:ok, %{"Organisations" => [org]}} = Organisation.get(token, tid)
      assert org["CountryCode"] == "AU"
    end
  end

  describe "actions/2" do
    test "returns organisation actions", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/Organisation/Actions", 200, %{
        "Actions" => [%{"Name" => "UseMulticurrency", "Enabled" => true}]
      })

      assert {:ok, %{"Actions" => [_]}} = Organisation.actions(token, tid)
    end
  end

  describe "cis_settings/2" do
    test "returns CIS settings for UK orgs", %{bypass: bypass, token: token, tenant_id: tid} do
      stub_xero(bypass, "GET", "/api.xro/2.0/Organisation/CISSettings", 200, %{
        "CISSettings" => [%{"CISContractorEnabled" => true}]
      })

      assert {:ok, _} = Organisation.cis_settings(token, tid)
    end
  end
end
