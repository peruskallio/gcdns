require 'test_helper'

class ZoneTest < ActiveSupport::TestCase

  @@zone_id = 1

  test "no permissions" do
    u,p,z,politics = zone_permission_test_vars

    policy_test({
      role: 'User with no permissions',
      policy: politics,
      permit: []
    })
  end

  test "zone manager permissions" do
    u,p,z,politics = zone_permission_test_vars

    u.add_role :zone_manager, p

    policy_test({
      role: 'Zone manager without permissions',
      policy: politics,
      permit: []
    })

    u.zone_permissions.create!(project: p, zone_id: z.id, name: :read)
    policy_test({
      role: 'Zone manager with read permissions',
      policy: politics,
      permit: :show
    })

    u.zone_permissions.destroy_all
    u.zone_permissions.create!(project: p, zone_id: z.id, name: :edit)
    policy_test({
      role: 'Zone manager with edit permissions',
      policy: politics,
      permit: :update
    })

    u.zone_permissions.destroy_all
    u.zone_permissions.create!(project: p, zone_id: z.id, name: :destroy)
    policy_test({
      role: 'Zone manager with destroy permissions',
      policy: politics,
      permit: :destroy
    })
  end

  test "zone creator permissions" do
    u,p,z,politics = zone_permission_test_vars

    u.add_role :zone_manager, p
    u.add_role :zone_creator, p

    policy_test({
      role: 'Zone creator',
      policy: politics,
      permit: :create
    })
  end

  test "admin permissions" do
    u,p,z,politics = zone_permission_test_vars

    u.add_role :admin, p

    policy_test({
      role: 'Project admin',
      policy: politics,
      permit: [:create, :show, :update, :destroy]
    })
  end

  test "import" do
  end

  private
    def zone_permission_test_vars
      u = User.first
      p = Project.first
      z = GRemote::Zone.new
      z.id = @@zone_id += 1
      z.project = p
      [u, p, z, ZonePolicy.new(u,z)]
    end
end
