require 'test_helper'

class ChangeSuggestionsControllerTest < ActionController::TestCase
  setup do
    @change_suggestion = change_suggestions(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:change_suggestions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create change_suggestion" do
    assert_difference('ChangeSuggestion.count') do
      post :create, change_suggestion: { description: @change_suggestion.description, done: @change_suggestion.done, pcc_communication_request_id: @change_suggestion.pcc_communication_request_id, priority: @change_suggestion.priority }
    end

    assert_redirected_to change_suggestion_path(assigns(:change_suggestion))
  end

  test "should show change_suggestion" do
    get :show, id: @change_suggestion
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @change_suggestion
    assert_response :success
  end

  test "should update change_suggestion" do
    put :update, id: @change_suggestion, change_suggestion: { description: @change_suggestion.description, done: @change_suggestion.done, pcc_communication_request_id: @change_suggestion.pcc_communication_request_id, priority: @change_suggestion.priority }
    assert_redirected_to change_suggestion_path(assigns(:change_suggestion))
  end

  test "should destroy change_suggestion" do
    assert_difference('ChangeSuggestion.count', -1) do
      delete :destroy, id: @change_suggestion
    end

    assert_redirected_to change_suggestions_path
  end
end
