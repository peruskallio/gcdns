class PermissionsController < ApplicationController

  before_action :set_project
  before_action :set_user

  def create
    if @email_invalid
      msg = { alert: "Invalid email." }
    elsif @user.nil?
      msg = { alert: "User was not found." }
    elsif @project.roles.any? { |r| @user.has_role?(r.name, @project) }
      msg = { alert: "User is already added to the project." }
    else
      @user.remove_role(:admin, @project)
      @user.remove_role(:zone_manager, @project)
      @user.add_role(params[:name], @project)
      msg = { notice: "User was added successfully." }
    end
    redirect_to edit_project_path(@project), msg
  end

  def update
    @user.remove_role(:admin, @project)
    @user.remove_role(:zone_manager, @project)
    @user.remove_role(:zone_creator, @project)
    if params[:name].is_a? Array
      params[:name].each do |name|
        @user.add_role(name, @project)
      end
    else
      @user.add_role(params[:name], @project)
    end

    if params.has_key?(:permissions)
      params[:permissions].each do |id, permissions|
        @user.zone_permissions.where(zone_id: id).destroy_all
        if !permissions.has_key?(:destroy_permission)
          @user.zone_permissions.create(zone_id: id, name: :read, project: @project) if permissions.has_key?("read")
          @user.zone_permissions.create(zone_id: id, name: :edit, project: @project) if permissions.has_key?("edit")
          @user.zone_permissions.create(zone_id: id, name: :destroy, project: @project) if permissions.has_key?("destroy")
        end
      end
    end

    redirect_to edit_project_path(@project), notice: "User was updated successfully."
  end

  def destroy
    @user.zone_permissions.where(project: @project).destroy_all
    @user.roles(@project).destroy_all
    redirect_to edit_project_path(@project), notice: "User was removed successfully."
  end

  private
    def set_project
      @project = Project.find(params[:project_id])
      authorize @project, :update?
    end

    def set_user
      if params.has_key?(:email)
        if params[:email] =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
          @user = User.find_by(email: params[:email])
        else
          @email_invalid = true
        end
      else
        @user = User.find(params[:id])
      end
      return redirect_to edit_project_path(@project), alert: "You can not edit your own credentials!" if @user == current_user

      if !@email_invalid && @user.nil? && current_user.has_role?(:system_admin)
        if params[:new_confirmed] && params[:new_confirmed] == "1"
          pass = Devise.friendly_token.first(8)
          @user = User.new(email: params[:email], password: pass, password_confirmation: pass)
          if @user.save
            @user.send_welcome_mail(current_user)
          else
            @email_invalid = true
          end
        else
          @email = params[:email]
          @name = params[:name]
          if @name == "admin"
            @role_name = "Admin"
          elsif @name == "zone_manager"
            @role_name = "Zone manager"
          else
            raise "Unknown role!"
          end
          return render "confirm_new_user"
        end
      end
    end

end
