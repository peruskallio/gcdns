# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

module GRemote
  class Changes < DnsModel

    attr_accessor :id, :zone, :additions, :deletions, :status, :start_time

    def save
      body = {}
      if self.additions
        body[:additions] = []
        self.additions.each do |resource|
          body[:additions].push(resource_to_data resource)
        end
      end
      if self.deletions
        body[:deletions] = []
        self.deletions.each do |resource|
          body[:deletions].push(resource_to_data resource)
        end
      end

      unless body[:additions] || body[:deletions]
        return false
      end

      result = @@helper.api_call do |service|
        @@helper.api_request service.changes.create, {
          project: @@project.project_key,
          managedZone: self.zone.id
        }, body
      end

      self.id = result.data.id
      self.start_time = result.data.start_time
      self.status = result.data.status

      # If the API call does not return an error, it is successful.
      # And if that happens, the parent class should already raise
      # an exception in that case.
      true
    end

    def self.find(id, zone_id_or_name)
      result = @@helper.api_call do |service|
        @@helper.api_request service.changes.get, {
          project: @@project.project_key,
          managedZone: zone_id_or_name,
          changeId: id
        }
      end
      self.initialize_from(result.data)
    end

    def self.list(zone_id_or_name)
      result = @@helper.api_call do |service|
        @@helper.api_request service.changes.list, {
          project: @@project.project_key,
          managedZone: zone_id_or_name
        }
      end

      changes = []
      if result.data["changes"]
        result.data["changes"].each do |record|
          changes.push(self.initialize_from(record))
        end
      end
      changes
    end

    protected

      def resource_to_data(resource)
        {
          name: resource.name,
          type: resource.type,
          ttl: resource.ttl,
          rrdatas: resource.rrdatas
        }
      end

  end
end