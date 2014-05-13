require 'test_helper'

class NotificationLogsControllerTest < ActionController::TestCase
  setup do
    @notification_log = notification_logs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:notification_logs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create notification_log" do
    assert_difference('NotificationLog.count') do
      post :create, notification_log: { date: @notification_log.date, text: @notification_log.text }
    end

    assert_redirected_to notification_log_path(assigns(:notification_log))
  end

  test "should show notification_log" do
    get :show, id: @notification_log
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @notification_log
    assert_response :success
  end

  test "should update notification_log" do
    put :update, id: @notification_log, notification_log: { date: @notification_log.date, text: @notification_log.text }
    assert_redirected_to notification_log_path(assigns(:notification_log))
  end

  test "should destroy notification_log" do
    assert_difference('NotificationLog.count', -1) do
      delete :destroy, id: @notification_log
    end

    assert_redirected_to notification_logs_path
  end
end
