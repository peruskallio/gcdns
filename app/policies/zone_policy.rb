class ZonePolicy < ApplicationPolicy
  def create?
    user.has_role?(:admin, record.project) || user.has_role?(:zone_creator, record.project)
  end

  def show?
    user.has_role?(:admin, record.project) || user.has_zone_permission?(record, :read)
  end

  def update?
    user.has_role?(:admin, record.project) || user.has_zone_permission?(record, :edit)
  end

  def destroy?
    user.has_role?(:admin, record.project) || user.has_zone_permission?(record, :destroy)
  end
end