class CreateZonePermissions < ActiveRecord::Migration
  def change
    create_table :zone_permissions do |t|
      t.integer :user_id, null: false
      t.integer :zone_id, null: false
      t.string :name, null: false
    end
  end
end
