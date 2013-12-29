require 'test_helper'

class EnquiriesControllerTest < ActionController::TestCase
  setup do
    @enquiry = enquiries(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:enquiries)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create enquiry" do
    assert_difference('Enquiry.count') do
      post :create, enquiry: { description: @enquiry.description, email: @enquiry.email, mobile: @enquiry.mobile, name: @enquiry.name, phone: @enquiry.phone, topic: @enquiry.topic }
    end

    assert_redirected_to enquiry_path(assigns(:enquiry))
  end

  test "should show enquiry" do
    get :show, id: @enquiry
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @enquiry
    assert_response :success
  end

  test "should update enquiry" do
    put :update, id: @enquiry, enquiry: { description: @enquiry.description, email: @enquiry.email, mobile: @enquiry.mobile, name: @enquiry.name, phone: @enquiry.phone, topic: @enquiry.topic }
    assert_redirected_to enquiry_path(assigns(:enquiry))
  end

  test "should destroy enquiry" do
    assert_difference('Enquiry.count', -1) do
      delete :destroy, id: @enquiry
    end

    assert_redirected_to enquiries_path
  end
end
