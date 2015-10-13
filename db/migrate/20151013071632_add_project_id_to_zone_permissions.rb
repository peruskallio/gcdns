class AddProjectIdToZonePermissions < ActiveRecord::Migration
  def change
    add_column :zone_permissions, :project_id, :integer
  end
end
