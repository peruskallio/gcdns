# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

class ApplicationController < ActionController::Base
  include Pundit
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_locale, :authenticate_user!, :set_projects

  protected

    def set_locale
      #I18n.locale = I18n.default_locale
      I18n.locale = :en
    end

    def set_projects
      if user_signed_in?
        @projects = Project.with_role([:zone_manager, :admin], current_user)
      end
    end

end
