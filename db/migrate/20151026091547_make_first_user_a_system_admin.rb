class MakeFirstUserASystemAdmin < ActiveRecord::Migration
  def change
    sys_admin = User.first
    sys_admin.add_role :system_admin unless sys_admin.nil?
  end
end
