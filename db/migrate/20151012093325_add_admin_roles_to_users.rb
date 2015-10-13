class AddAdminRolesToUsers < ActiveRecord::Migration
  def change
    # Adds admin role for each project & user combination
    # in the database.
    Project.all.each do |p|
      User.all.each do |u|
        u.add_role :admin, p
      end
    end
  end
end
