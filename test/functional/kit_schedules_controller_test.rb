require 'test_helper'

class KitSchedulesControllerTest < ActionController::TestCase
  setup do
    @kit_schedule = kit_schedules(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:kit_schedules)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create kit_schedule" do
    assert_difference('KitSchedule.count') do
      post :create, kit_schedule: {  }
    end

    assert_redirected_to kit_schedule_path(assigns(:kit_schedule))
  end

  test "should show kit_schedule" do
    get :show, id: @kit_schedule
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @kit_schedule
    assert_response :success
  end

  test "should update kit_schedule" do
    put :update, id: @kit_schedule, kit_schedule: {  }
    assert_redirected_to kit_schedule_path(assigns(:kit_schedule))
  end

  test "should destroy kit_schedule" do
    assert_difference('KitSchedule.count', -1) do
      delete :destroy, id: @kit_schedule
    end

    assert_redirected_to kit_schedules_path
  end
end
