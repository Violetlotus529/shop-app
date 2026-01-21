require "test_helper"

class Admin::InventoriesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_inventories_index_url
    assert_response :success
  end
end
