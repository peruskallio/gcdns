# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

module GRemote
  class RecordSet < DnsModel
    
    attr_accessor :type, :name, :ttl, :rrdatas
    
    def self.list_for(zone_id_or_name, extra={})
      # Fetch the records list
      extra_keys = [:name, :type]
      result = @@helper.api_call do |service|
        @@helper.api_request service.resource_record_sets.list, {
          project: @@project.project_key,
          managedZone: zone_id_or_name,
        }.merge(
          extra.select { |k,v| extra_keys.include?(k) && !v.nil? && v.length > 0 }
        )
      end
      
      rrsets = []
      if result.data["rrsets"]
        result.data["rrsets"].each do |record|
          rrsets.push(self.initialize_from(record))
        end
      end
      rrsets
    end
    
  end
end