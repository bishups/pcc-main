require 'test_helper'

class PccCommunicationRequestsControllerTest < ActionController::TestCase
  setup do
    @pcc_communication_request = pcc_communication_requests(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:pcc_communication_requests)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create pcc_communication_request" do
    assert_difference('PccCommunicationRequest.count') do
      post :create, pcc_communication_request: { attachment: @pcc_communication_request.attachment, last_update: @pcc_communication_request.last_update, last_updated_at: @pcc_communication_request.last_updated_at, last_updated_by_user_id: @pcc_communication_request.last_updated_by_user_id, purpose: @pcc_communication_request.purpose, requester_id: @pcc_communication_request.requester_id, state: @pcc_communication_request.state, target_audience: @pcc_communication_request.target_audience }
    end

    assert_redirected_to pcc_communication_request_path(assigns(:pcc_communication_request))
  end

  test "should show pcc_communication_request" do
    get :show, id: @pcc_communication_request
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @pcc_communication_request
    assert_response :success
  end

  test "should update pcc_communication_request" do
    put :update, id: @pcc_communication_request, pcc_communication_request: { attachment: @pcc_communication_request.attachment, last_update: @pcc_communication_request.last_update, last_updated_at: @pcc_communication_request.last_updated_at, last_updated_by_user_id: @pcc_communication_request.last_updated_by_user_id, purpose: @pcc_communication_request.purpose, requester_id: @pcc_communication_request.requester_id, state: @pcc_communication_request.state, target_audience: @pcc_communication_request.target_audience }
    assert_redirected_to pcc_communication_request_path(assigns(:pcc_communication_request))
  end

  test "should destroy pcc_communication_request" do
    assert_difference('PccCommunicationRequest.count', -1) do
      delete :destroy, id: @pcc_communication_request
    end

    assert_redirected_to pcc_communication_requests_path
  end
end
