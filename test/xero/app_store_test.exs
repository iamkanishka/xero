defmodule Xero.AppStoreTest do
  @moduledoc false

  use Xero.Test.HTTPCase, async: true

  alias Xero.AppStore

  describe "list_subscriptions/1" do
    test "returns subscriptions list", %{bypass: bypass, token: token} do
      stub_xero(bypass, "GET", "/appstore/2.0/subscriptions", 200, %{
        "subscriptions" => [%{"subscriptionId" => "sub-1", "status" => "ACTIVE"}]
      })

      assert {:ok, _} = AppStore.list_subscriptions(token)
    end
  end

  describe "get_subscription/2" do
    test "returns a single subscription", %{bypass: bypass, token: token} do
      stub_xero(bypass, "GET", "/appstore/2.0/subscriptions/sub-abc", 200, %{
        "subscriptionId" => "sub-abc",
        "status" => "ACTIVE"
      })

      assert {:ok, _} = AppStore.get_subscription(token, "sub-abc")
    end

    test "returns :not_found for unknown subscription", %{bypass: bypass, token: token} do
      stub_xero(bypass, "GET", "/appstore/2.0/subscriptions/ghost", 404, %{})

      assert {:error, %Xero.Error{type: :not_found}} =
               AppStore.get_subscription(token, "ghost")
    end
  end

  describe "create_usage_record/4" do
    test "POSTs usage record", %{bypass: bypass, token: token} do
      Bypass.expect_once(
        bypass,
        "POST",
        "/appstore/2.0/subscriptions/sub-1/plans/plan-1/UsageRecords",
        fn conn ->
          {:ok, body, conn} = Plug.Conn.read_body(conn)
          decoded = Jason.decode!(body)
          assert decoded["quantity"] == 5.0

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, Jason.encode!(%{"usageRecordId" => "ur-1"}))
        end
      )

      assert {:ok, _} =
               AppStore.create_usage_record(token, "sub-1", "plan-1", %{
                 "quantity" => 5.0,
                 "timestamp" => "2024-01-15T12:00:00Z",
                 "productId" => "seats",
                 "priceId" => "per-seat"
               })
    end
  end

  describe "list_usage_records/3" do
    test "returns usage records", %{bypass: bypass, token: token} do
      stub_xero(
        bypass,
        "GET",
        "/appstore/2.0/subscriptions/sub-1/plans/plan-1/UsageRecords",
        200,
        %{
          "usageRecords" => []
        }
      )

      assert {:ok, _} = AppStore.list_usage_records(token, "sub-1", "plan-1")
    end
  end
end
