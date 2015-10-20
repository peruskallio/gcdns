# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

module GRemote
  class Zone < DnsModel

    attr_accessor :id, :name, :description, :dns_name, :project_id

    def self.policy_class
      ZonePolicy
    end

    def initialize
      super
      @project_id = @@project.id rescue nil
    end

    def project
      Project.find(@project_id)
    end

    def project=(project)
      @project_id = project.id rescue nil
    end

    def recordsets
      # Fetch the records list
      GRemote::RecordSet.list_for(self.id ? self.id : self.name)
    end

    # Find recordsets by params (e.g. recordsets_by(name: 'domain.com', type: 'SOA'))
    def recordsets_by(params)
      GRemote::RecordSet.list_for(self.id ? self.id : self.name, params)
    end

    def soa_record
      self.recordsets.detect { |rs| rs.type == "SOA" }
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

    def export(ttl, rsets=nil)
      rsets ||= self.recordsets
      # Order the records in the following order.
      record_order = ["SOA", "NS", "A", "AAAA", "CNAME", "MX", "PTR", "SPF", "SRV", "TXT"]

      zonefile = ""
      # First we want to sort the records properly
      records = {}
      names = []

      lengths = {
        name: 0,
        ttl: 0,
        type: 0
      }

      rsets.each do |rset|
        rttl = rset.ttl.to_s
        rttl = "" if rttl == ttl

        name = rset.name
        if name == self.dns_name
          # domain.com. => @
          name = '@'
        elsif name.end_with?("." + self.dns_name)
          # E.g. subdomain.domain.com. => subdomain
          name = name[0, name.length - self.dns_name.length - 1]
        end

        lengths[:name] = name.length if name.length > lengths[:name]
        lengths[:ttl] = rttl.length if rttl.length > lengths[:ttl]
        lengths[:type] = rset.type.length if rset.type.length > lengths[:type]

        records[name] = {} unless records[name]
        records[name][rset.type] = [] unless records[name][rset.type]

        rset.rrdatas.each do |rdata|
          records[name][rset.type].push({
            ttl: rttl,
            data: rdata
          })
        end

        names.push(name) unless names.include?(name)
      end

      names.sort do |a, b|
        if a != b
          # '@' Comes always as the first one in the list
          if a == '@'
            -1
          else # b == '@'
            1
          end
        else
          a <=> b
        end
      end

      # After that, write the zone file.
      # We want to create this manually because we want to format
      # the zone file properly.
      zonefile += "$TTL " + ttl
      zonefile += "\n$ORIGIN " + self.dns_name
      zonefile += "\n"

      names.each do |name|
        recname = name
        types = records[name].keys
        types.sort do |a, b|
          record_order.index(a) <=> record_order.index(b)
        end
        types.each do |type|
          records[name][type].each do |rdata|
            zonefile += "\n" + recname.ljust(lengths[:name], ' ')
            zonefile += " " + rdata[:ttl].ljust(lengths[:ttl], ' ')
            zonefile += " IN " + type.ljust(lengths[:type])
            zonefile += " " + rdata[:data]

            # Following lines with the same name do not need the name to be repeated
            recname = ""
          end
        end
        zonefile += "\n"
      end
      zonefile
    end

    def self.import(zone_string, domain, domain_dns)
      # Load zone and read its data
      errors = []
      additions = []
      zone_records = {}
      num_records = 0

      dns_zone = DNS::Zone.load(zone_string)

      zone_origin = dns_zone.origin
      zone_origin += "." unless zone_origin.ends_with?('.')

      dns_zone.records.each do |rec|
        data = nil

        # Please note that we will ignore the SOA
        # record and top level NS record intentionally!
        if rec.is_a?(DNS::Zone::RR::NS) && !['@', zone_origin].include?(rec.label)
          data = rec.nameserver
        elsif rec.is_a?(DNS::Zone::RR::PTR)
          data = rec.name
        elsif rec.is_a?(DNS::Zone::RR::A)
          data = rec.address
        elsif rec.is_a?(DNS::Zone::RR::AAAA)
          data = rec.address
        elsif rec.is_a?(DNS::Zone::RR::CNAME)
          data = hostname(rec.domainname, dns_zone.origin)
        elsif rec.is_a?(DNS::Zone::RR::MX)
          data = rec.priority.to_s + " " + hostname(rec.exchange, dns_zone.origin)
        elsif rec.is_a?(DNS::Zone::RR::SPF)
          data = rec.text
        elsif rec.is_a?(DNS::Zone::RR::SRV)
          data = rec.priority.to_s + " " + rec.weight.to_s + " " + rec.port.to_s + " " + hostname(rec.target, dns_zone.origin)
        elsif rec.is_a?(DNS::Zone::RR::TXT)
          data = rec.text.strip
          if /\s/ =~ data
            # If the data contains spaces, it needs to be enclosed in quotes.
            # See: https://cloud.google.com/dns/what-is-cloud-dns#supported_record_types (TXT)
            # "If one of your strings contains embedded white space, you must use the quoted form"
            data = '"' + data + '"'
          end
        end

        # We don't want to import empty data records because
        # the Google DNS API does not like them (as it shouldn't).
        if !data.nil? && data.strip.length > 0
          # Default TTL is 24h (86400s) if it has not been set for the zone.
          ttl = rec.ttl.nil? ? (dns_zone.ttl.nil? ? 21600 : dns_zone.ttl) : rec.ttl
          ttl = ttl.to_s

          name = rec.label
          if name == '@'
            name = zone_origin
          else
            name = hostname(name, dns_zone.origin)
          end

          zone_records[name] = {} unless zone_records[name]

          datas = []
          if zone_records[name][rec.type]
            # The Google DNS API does not allow multiple records of the
            # same type with the same name, so the additional records
            # need to be set within the same zone
            datas = zone_records[name][rec.type][:datas]
          end
          datas.push(data)

          zone_records[name][rec.type] = {
            :ttl => ttl,
            :datas => datas
          }
          num_records += 1
        end
      end

      if num_records > 0
        # Create the remote zone
        zone = GRemote::Zone.new
        zone.name = domain.gsub(/[$!*()]/, '').gsub(/\.$/, '').gsub(/[._+]/, '-')
        zone.description = ""
        zone.dns_name = domain_dns

        if errors.length < 1
          # Add the records to a changes request and send it to the API.

          zone_records.each do |name, typedatas|
            typedatas.each do |type, details|

              # Sort the datas before adding them to the RecordSet object.
              # We want the MX and SRV records to be sorted by their priority
              # as the first criteria.
              datas = details[:datas].sort do |a, b|
                if type == 'MX' || type == 'SRV'
                  aparts = a.split(" ")
                  bparts = b.split(" ")

                  if aparts[0].to_i == bparts[0].to_i
                    # Compare the MX/SRV record strings without the priority part
                    aparts[1..-1].join(" ") <=> bparts[1..-1].join(" ")
                  else
                    # Compare the MX/SRV priorities if they are not equal
                    aparts[0].to_i <=> bparts[0].to_i
                  end
                else
                  a <=> b
                end
              end

              rset = GRemote::RecordSet.new
              rset.name = name
              rset.type = type
              rset.ttl = details[:ttl]
              rset.rrdatas = datas
              additions.push(rset)
            end
          end
        end
      else
        errors.push("No records found for the zone.")
      end
      { errors: errors, additions: additions, zone: zone, dns_zone: dns_zone }
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

    private
      def self.hostname(localname, zone_origin)
        final = localname.strip

        if final[-1, 1] != '.'
          # Change short name into a full name. Google Clound DNS requires
          # the domain names to be in their full format. Please see:
          # https://cloud.google.com/dns/migrating-bind-differences
          final += "." + zone_origin
          final += "." unless /\.$/.match(zone_origin)
        end

        final
      end
  end
end