# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

class ProjectsController < ApplicationController
  
  before_action :set_project, except: [:index, :new, :create]

  # GET /projects
  # GET /projects.json
  def index
    #@projects = Project.all
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
  end

  # GET /projects/new
  def new
    @project = Project.new
    @project.keypass = 'notasecret'
  end

  # GET /projects/1/edit
  def edit
  end

  # POST /projects
  # POST /projects.json
  def create
    @project = Project.new(save_params)

    respond_to do |format|
      if @project.save
        format.html { redirect_to @project, notice: 'Project was successfully created.' }
        format.json { render :show, status: :created, location: @project }
      else
        format.html { render :new }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /projects/1
  # PATCH/PUT /projects/1.json
  def update
    respond_to do |format|
      saveparams = save_params
      if saveparams[:keydata].nil?
        saveparams.delete(:keydata)
      end
      if @project.update(saveparams)
        format.html { redirect_to @project, notice: 'Project was successfully updated.' }
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project.destroy
    respond_to do |format|
      format.html { redirect_to root_url, notice: 'Project was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  private
  
    # Use callbacks to share common setup or constraints between actions.
    def set_project
      if params[:project_id]
        @project = Project.find(params[:project_id])
      else
        @project = Project.find(params[:id])
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def project_params
      params.require(:project).permit(:name, :project_key, :issuer, :keydata, :keypass)
    end
    
    # Changes the uploaded file data into text data to be saved into the DB
    def save_params
      saveparams = project_params.clone
      uploaded_file = saveparams[:keydata]
      unless uploaded_file.nil?
        # Save only the file data
        saveparams[:keydata] = uploaded_file.read
      end
      saveparams
    end
    
end
