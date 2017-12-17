require 'test_helper'

class CheckersAppControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get checkers_app_index_url
    assert_response :success
  end

end
