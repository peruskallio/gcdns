class ZonePolicy < ApplicationPolicy
  def show?
    user.can_read_zone?(record)
  end

  def update?
    user.can_edit_zone?(record)
  end

  def destroy?
    user.can_destroy_zone?(record)
  end
end