require 'test_helper'

class NotificationsControllerTest < ActionController::TestCase
  setup do
    @notification = notifications(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:notifications)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create notification" do
    assert_difference('Notification.count') do
      post :create, notification: { additional_text: @notification.additional_text, from_state: @notification.from_state, model: @notification.model, on_event: @notification.on_event, role_id: @notification.role_id, send_email: @notification.send_email, send_sms: @notification.send_sms, to_state: @notification.to_state }
    end

    assert_redirected_to notification_path(assigns(:notification))
  end

  test "should show notification" do
    get :show, id: @notification
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @notification
    assert_response :success
  end

  test "should update notification" do
    put :update, id: @notification, notification: { additional_text: @notification.additional_text, from_state: @notification.from_state, model: @notification.model, on_event: @notification.on_event, role_id: @notification.role_id, send_email: @notification.send_email, send_sms: @notification.send_sms, to_state: @notification.to_state }
    assert_redirected_to notification_path(assigns(:notification))
  end

  test "should destroy notification" do
    assert_difference('Notification.count', -1) do
      delete :destroy, id: @notification
    end

    assert_redirected_to notifications_path
  end
end
