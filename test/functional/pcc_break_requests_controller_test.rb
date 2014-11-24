require 'test_helper'

class PccBreakRequestsControllerTest < ActionController::TestCase
  setup do
    @pcc_break_request = pcc_break_requests(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:pcc_break_requests)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create pcc_break_request" do
    assert_difference('PccBreakRequest.count') do
      post :create, pcc_break_request: { comment_category: @pcc_break_request.comment_category, comments: @pcc_break_request.comments, days: @pcc_break_request.days, from: @pcc_break_request.from, last_update: @pcc_break_request.last_update, last_updated_at: @pcc_break_request.last_updated_at, last_updated_by_user_id: @pcc_break_request.last_updated_by_user_id, purpose: @pcc_break_request.purpose, requester_id: @pcc_break_request.requester_id, state: @pcc_break_request.state, to: @pcc_break_request.to }
    end

    assert_redirected_to pcc_break_request_path(assigns(:pcc_break_request))
  end

  test "should show pcc_break_request" do
    get :show, id: @pcc_break_request
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @pcc_break_request
    assert_response :success
  end

  test "should update pcc_break_request" do
    put :update, id: @pcc_break_request, pcc_break_request: { comment_category: @pcc_break_request.comment_category, comments: @pcc_break_request.comments, days: @pcc_break_request.days, from: @pcc_break_request.from, last_update: @pcc_break_request.last_update, last_updated_at: @pcc_break_request.last_updated_at, last_updated_by_user_id: @pcc_break_request.last_updated_by_user_id, purpose: @pcc_break_request.purpose, requester_id: @pcc_break_request.requester_id, state: @pcc_break_request.state, to: @pcc_break_request.to }
    assert_redirected_to pcc_break_request_path(assigns(:pcc_break_request))
  end

  test "should destroy pcc_break_request" do
    assert_difference('PccBreakRequest.count', -1) do
      delete :destroy, id: @pcc_break_request
    end

    assert_redirected_to pcc_break_requests_path
  end
end
