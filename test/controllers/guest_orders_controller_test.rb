require "test_helper"

class GuestOrdersControllerTest < ActionDispatch::IntegrationTest
  test "should get lookup" do
    get guest_orders_lookup_url
    assert_response :success
  end
end
