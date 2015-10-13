# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

class ZonesController < RemoteController

  before_action :set_project, only: [:show, :index, :new, :create, :destroy]

  def index
    @zones = current_user.allowed_zones(GRemote::Zone.list, @project, :read)
  end

  # GET /projects/:project_id/zones/:zone_id
  def show
    zone = GRemote::Zone.new
    zone.id = params[:id]
    authorize zone unless current_user.has_role?(:admin, @project)
    @can_edit = current_user.has_role?(:admin, @project) || current_user.can_edit_zone?(zone)
  end

  def new
    authorize @project, :create_zone?
  end

  # POST /projects/:project_id/zones
  def create
    error = nil
    authorize @project, :create_zone?
    begin
      @zone = GRemote::Zone.new
      @zone.name = params[:name]
      @zone.description = params[:description]
      @zone.dns_name = params[:dns_name]
      @zone.save
      current_user.create_permissions_for_new_zone(@zone, @project)
    rescue Exception => e
      error = e.message
    end

    if error
      flash[:alert] = error
    else
      return redirect_to project_zones_path(@project), notice: 'Zone was successfully added.'
    end

    render :new
  end

  def update
    # TODO: Write zone updating functionality...

    render "testing"
  end

  def destroy
    error = nil
    begin
      # We could also fetch the object with the .find method
      # but that would cause an extra API request which is
      # not necessary here.
      @zone = GRemote::Zone.new
      @zone.id = params[:id]
      authorize @zone unless current_user.has_role? :admin, @project
      @zone.delete
    rescue Exception => e
      error = e.message
      raise e
    end

    if error
      flash[:alert] = error
    else
      return redirect_to project_zones_path(@project), notice: 'Zone was successfully deleted.'
    end

    index
    render :index
  end

end
