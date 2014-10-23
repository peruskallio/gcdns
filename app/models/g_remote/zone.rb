# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

module GRemote
  class Zone < DnsModel
    
    attr_accessor :id, :name, :description, :dns_name
    
    def recordsets
      # Fetch the records list
      GRemote::RecordSet.list_for(self.id ? self.id : self.name)
    end
    
    # Find recordsets by params (e.g. recordsets_by(name: 'domain.com', type: 'SOA'))
    def recordsets_by(params)
      GRemote::RecordSet.list_for(self.id ? self.id : self.name, params)
    end
    
    def soa_record
      self.recordsets_by(name: self.dns_name, type: 'SOA').detect do |rset|
        rset.name == self.dns_name && rset.type == 'SOA'
      end
    end
    
    def update_soa(params={})
      soa = self.soa_record
      current = soa.rrdatas.first.split(/\s+/)
      
      # NOTE:
      # The serial needs to be incremented every time updates are made
      # so we do not allow passing any parameters that define this.
      # The serial is an unsigned 32 bit integer between 0 and 4294967295.
      
      # We allow updating the domain authority email (1)
      # The serial (2) is incremented automatically by 1.
      # 0: Primary name server
      updated = current[0] 
      
      # 1: Email for the responsible party of the domain
      if params[:email]
        updated += " " + params[:email]
      else
        updated += " " + current[1]
      end
      
      # 2: Serial
      serial = current[2]
      
      # TODO: The serial format could be configurable option (application config).
      # TODO: The same configuration should apply here and in the frontend (Records controller).
      if true
        # Default single digit format, incremeted by 1 when updated.
        # This is the default format because it does not place any
        # constraints in the amount of daily allowed changes.
        serial = (serial.to_i + 1).to_s
      else
        # YYYYMMDDnn format, where:
        # YYYYMMDD = the current date
        # nn = increment within that date (if there are multiple changes within a day)
        date = DateTime.now.strftime("%Y%m%d")
        increment = 0
        if serial.length == 10
          curdate = serial[0..7]
          if curdate == date
            increment = serial[7..9].to_i
          end
        end
        if increment > 98
          # TODO: Custom Exception class so that the error can be detected
          raise "Too many changes to the DNS record within this day. Only 99 changes allowed within a single day."
        end
        serial = date + ("%.2d" % (increment + 1))
      end
      
      updated += " " + serial
      
      # 3: Refresh interval
      # 4: Retry time
      # 5: Expiry time
      # 6: Minimum TTL
      updated += " " + current[3..6].join(" ")
      
      # Create an updated RecordSet
      upd_soa = GRemote::RecordSet.new
      upd_soa.name = soa.name
      upd_soa.type = soa.type
      upd_soa.ttl = soa.ttl
      upd_soa.rrdatas = [updated]
      
      # Send the changes request
      changes = GRemote::Changes.new
      changes.zone = self
      changes.additions = [upd_soa]
      changes.deletions = [soa]
      changes.save
    end
    
    def save
      result = @@helper.api_call do |service|
        @@helper.api_request service.managed_zones.create, {
          project: @@project.project_key
        }, {
          name: self.name,
          description: self.description,
          dnsName: self.dns_name
        }
      end
      
      self.id = result.data.id
      
      # If the API call does not return an error, it is successful.
      # And if that happens, the parent class should already raise
      # an exception in that case.
      true
    end
    
    def delete
      # The zone needs to be empty in order for it to allow its deletion.
      # However, we do not need to delete the original records, i.e. the
      # SOA and NS records for the dns_name of the zone.
      target = self
      unless target.dns_name
        # We need to fetch the zone from the API in order to resolve its
        # dns_name if the current record has not been fetched through the
        # API.
        target = GRemote::Zone.find(self.id)
      end
      changes = GRemote::Changes.new
      changes.zone = target
      changes.deletions = self.recordsets.select do |rset|
        rset.name != target.dns_name || (rset.type != 'SOA' && rset.type != 'NS')
      end
      if changes.deletions.length > 0
        unless changes.save
          raise "Error deleting the zone records."
        end
      end
      
      begin
        result = @@helper.api_call do |service|
          @@helper.api_request service.managed_zones.delete, {
            project: @@project.project_key,
            managedZone: self.id
          }
        end
      rescue GoogleApi::InvalidRecordError
        # If the record is successfully deleted, it
        # does not return a record and this error
        # should be disregarded.
      end
      
      # If the API call does not return an error, it is successful.
      # And if that happens, the parent class should already raise
      # an exception in that case.
      true
    end
    
    def self.find(id_or_name)
      result = @@helper.api_call do |service|
        @@helper.api_request service.managed_zones.get, {
          project: @@project.project_key,
          managedZone: id_or_name
        }
      end
      self.initialize_from(result.data)
    end
    
    def self.list
      result = @@helper.api_call do |service|
        @@helper.api_request service.managed_zones.list, {
          project: @@project.project_key
        }
      end
      
      zones = []
      if result.data["managedZones"]
        result.data["managedZones"].each do |record|
          zones.push(self.initialize_from(record))
        end
      end
      zones
    end
    
  end
end