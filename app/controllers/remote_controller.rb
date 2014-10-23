# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

class RemoteController < ApplicationController
  
  before_action :set_project
  
  private
  
    # Use callbacks to share common setup or constraints between actions.
    def set_project
      @project = Project.find(params[:project_id])
      
      unless @project.nil?
        GRemote::DnsModel.initialize_api(@project)
      end
    end
  
end