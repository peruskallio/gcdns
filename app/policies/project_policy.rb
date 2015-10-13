class ProjectPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.has_role?(:admin, record) || user.has_role?(:zone_manager, record)
  end

  def update?
    user.has_role? :admin, record
  end

  def destroy?
    update?
  end

  def create_zone?
    user.has_role?(:admin, record) || (user.has_role?(:zone_manager, record) && user.has_role?(:zone_creator, record))
  end

end