require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "no permissions" do
    u, u2, politics = user_permission_test_vars
    u.remove_role :system_admin

    policy_test({
      role: 'User without a role',
      policy: politics,
      permit: []
    })
  end

  test "system admin permissions" do
    u, u2, politics = user_permission_test_vars
    u.add_role :system_admin

    policy_test({
      role: 'User without a role',
      policy: politics,
      permit: [:index, :show, :edit, :update, :create, :destroy]
    })
  end

  private
    def user_permission_test_vars
      u = User.first
      u2 = User.second
      [u, u2, UserPolicy.new(u, u2)]
    end
end
