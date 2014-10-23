# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

require 'google/api/dns'

module GRemote
  class DnsModel < GoogleApi::Dns::RemoteModel
    
    def self.initialize_api(project)
      @@project = project
      @@api_client = project.api_client('https://www.googleapis.com/auth/ndev.clouddns.readwrite')
      
      initialize_helper
    end
    
  end
end