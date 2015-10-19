require 'test_helper'

class ProjectTest < ActiveSupport::TestCase

  test "no permissions" do
    u, p, politics = project_permission_test_vars

    policy_test({
      role: 'User without a role',
      policy: politics,
      permit: :index
    })
  end

  test "admin permissions" do
    u, p, politics = project_permission_test_vars
    u.add_role :admin, p

    policy_test({
      role: 'Project admin',
      policy: politics,
      permit: [:index, :show, :update, :destroy]
    })
  end

  test "zone manager permissions" do
    u, p, politics = project_permission_test_vars
    u.add_role :zone_manager, p

    policy_test({
      role: 'Zone manager',
      policy: politics,
      permit: [:index, :show]
    })

  end

  private
    def project_permission_test_vars
      u = User.first
      p = Project.first
      [u, p, ProjectPolicy.new(u, p)]
    end

end
