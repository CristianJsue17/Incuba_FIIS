require "test_helper"

class ProgramsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get programs_index_url
    assert_response :success
  end
end
