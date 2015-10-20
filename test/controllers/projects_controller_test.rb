require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  setup do
    @project = projects(:one)
    u = User.first
    u.add_role :admin, @project
    sign_in u
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:projects)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create project" do
    assert_difference('Project.count') do
      post :create, project: { name: "New project", project_key: 'some-key', issuer: @project.issuer, keydata: fixture_upload("keydata", "application/json"), keypass: @project.keypass }
    end

    assert_redirected_to project_path(assigns(:project))
  end

  test "should show project" do
    get :show, id: @project
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @project
    assert_response :success
  end

  test "should update project" do
    patch :update, id: @project, project: { issuer: @project.issuer, keydata: fixture_upload("keydata", "application/json"), keypass: @project.keypass }
    assert_redirected_to project_path(assigns(:project))
  end

  test "should destroy project" do
    assert_difference('Project.count', -1) do
      delete :destroy, id: @project
    end

    assert_redirected_to root_url
  end
end
