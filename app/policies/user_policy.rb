class UserPolicy < ApplicationPolicy
  def index?
    user.has_role? :system_admin
  end

  def update?
    user.has_role? :system_admin
  end

  def destroy?
    update?
  end

end