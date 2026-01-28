require "test_helper"

class CheckoutsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get checkouts_create_url
    assert_response :success
  end

  test "should get build_cart_rows!" do
    get checkouts_build_cart_rows!_url
    assert_response :success
  end
end
