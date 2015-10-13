class PermissionsController < ApplicationController

  before_action :set_project
  before_action :set_user

  def create
    @user.remove_role(:admin, @project)
    @user.remove_role(:zone_manager, @project)
    @user.add_role(params[:name], @project)

    respond_to do |format|
      format.html { redirect_to edit_project_path(@project), notice: "User was added successfully." }
      format.json { render :show, status: :ok, location: @project }
    end
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

    respond_to do |format|
      format.html { redirect_to edit_project_path(@project), notice: "User was updated successfully." }
      format.json { render :show, status: :ok, location: @project }
    end
  end

  def destroy
    @user.zone_permissions.where(project: @project).destroy_all
    @user.roles(@project).destroy_all
    respond_to do |format|
      format.html { redirect_to edit_project_path(@project), notice: "User was removed successfully." }
      format.json { render :show, status: :ok, location: @project }
    end
  end

  private
    def set_project
      @project = Project.find(params[:project_id])
      authorize @project, :update?
    end

    def set_user
      @user = User.find(params[:id])
      raise "Unauthorized" if @user == current_user
    end

end
