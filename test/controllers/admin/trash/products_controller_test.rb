require "test_helper"

class Admin::Trash::ProductsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_trash_products_index_url
    assert_response :success
  end

  test "should get show" do
    get admin_trash_products_show_url
    assert_response :success
  end
end
