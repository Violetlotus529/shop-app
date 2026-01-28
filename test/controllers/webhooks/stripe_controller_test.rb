require "test_helper"

class Webhooks::StripeControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get webhooks_stripe_create_url
    assert_response :success
  end
end
