# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

class ZonesImportController < RemoteController

  skip_before_action :verify_authenticity_token, only: [:process_zone, :process_done]
  before_action :authorize_project

  def index

  end

  def create
    # Add an empty zone to the end of the data string so that the
    # last actual zone is also added to the zones array.
    if params[:data].nil?
      flash[:alert] = "Zone file data not defined."
      return redirect_to action: "index"
    end

    data = params[:data] + "\n$ORIGIN empty.com"

    # Go through the data and store each zone into its own string
    zones = {}
    @domains = []
    domain = nil
    ttl = 24600
    current = ''
    data.each_line do |line|
      # The following string always starts a new zone:
      # $ORIGIN domain.com
      matches = /^\$ORIGIN\s+([^\s]+)/.match(line)
      unless matches.nil?
        # If the domain is defined from the last round
        # we need to save the last zone into memory.
        unless domain.nil?
          @domains.push(domain)
          zones[domain] = current
          ttl = 21600
          current = ''
        end
        domain = matches[1]
      end
      matches_ttl = /^\$TTL\s([0-9]+)/.match(line)
      unless matches_ttl.nil?
        ttl = matches_ttl[1].to_i
      end
      current += line
    end

    if @domains.length > 0
      @id = save_zones(zones)
      @project = Project.find(params[:project_id])
    else
      flash.now[:alert] = "No zones defined in the import data."
      render action: "index"
    end
  end

  def process_zone
    errors = []
    zones = fetch_zones(params[:import_id])

    if zones
      domain = params[:zone]
      domain_dns = domain + '.'

      # Check that there is not an existing zone with this name already
      # in the API. Currently we do not allow importing existing records
      # due to the load it might cause for a single request. If the user
      # wants to improt existing zone, the zone needs to be removed first.

      # TODO: This does not currently handle paging of the zone listing...
      # There is also currently no way to do search calls to the API.
      project = Project.find(params[:project_id])
      GRemote::DnsModel.initialize_api(project)
      GRemote::Zone.list.each do |zone|
        if zone.dns_name == domain_dns
          errors.push("A zone already exists with the DNS name '%s'." % domain_dns)
        end
      end

      zone_string = zones[domain] if errors.length < 1

      if zone_string
        # Load zone and read its data

        zone_records = {}
        num_records = 0

        zone = DNS::Zone.load(zone_string)

        zone.records.each do |rec|
          # We do not handle SOA or NS records for the import.
          data = nil
          if rec.is_a?(DNS::Zone::RR::A)
            data = rec.address
          elsif rec.is_a?(DNS::Zone::RR::AAAA)
            data = rec.address
          elsif rec.is_a?(DNS::Zone::RR::CNAME)
            data = hostname(rec.domainname, zone.origin)
          elsif rec.is_a?(DNS::Zone::RR::MX)
            data = rec.priority.to_s + " " + hostname(rec.exchange, zone.origin)
          elsif rec.is_a?(DNS::Zone::RR::SPF)
            data = rec.text
          elsif rec.is_a?(DNS::Zone::RR::SRV)
            data = rec.priority.to_s + " " + rec.weight.to_s + " " + rec.port.to_s + " " + hostname(rec.target, zone.origin)
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
            ttl = rec.ttl.nil? ? (zone.ttl.nil? ? 21600 : zone.ttl) : rec.ttl
            ttl = ttl.to_s

            name = rec.label
            if name == '@'
              name = zone.origin + "."
            else
              name = hostname(name, zone.origin)
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
          zone = nil
          begin
            zone = GRemote::Zone.new
            zone.name = domain.gsub(/[$!*()]/, '').gsub(/[._+]/, '-')
            zone.description = ""
            zone.dns_name = domain_dns
            zone.save
            current_user.create_permissions_for_new_zone(zone, @project)
          rescue Exception => e
            errors.push(e.message)
          end

          if errors.length < 1
            # Add the records to a changes request and send it to the API.
            additions = []
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

            begin
              changes = GRemote::Changes.new
              changes.zone = zone
              changes.additions = additions
              changes.save

              zone.update_soa
            rescue Exception => e
              errors.push(e.message)
            end
          end
        else
          errors.push("No records found for the zone.")
        end
      end
    else
      errors.push("Cannot find the import data.")
    end

    if errors.length > 0
      render json: {success: 0, errors: errors}
    else
      render json: {success: 1}
    end
  end

  def process_done
    error = nil
    begin
      clear_zones(params[:import_id])
    rescue Exception => e
      error = e.message
    end

    if error
      render json: {success: 0, error: error}
    else
      render json: {success: 1}
    end
  end

  private

    def hostname(localname, zone_origin)
      final = localname.strip

      if final[-1, 1] != '.'
        # Change short name into a full name. Google Clound DNS requires
        # the domain names to be in their full format. Please see:
        # https://cloud.google.com/dns/migrating-bind-differences
        final += "." + zone_origin + "."
      end

      final
    end

    def fetch_zones(id)
      JSON.load(File.open(tmp_file(id), 'r') { |f| f.read })
    end

    def clear_zones(id)
      file = tmp_file(id)
      File.delete(file) if File.exist?(file)
    end

    def save_zones(zones)
      # Create random ID for the saved data.
      id = SecureRandom.hex(16)

      # And save it
      File.open(tmp_file(id), 'w', 0600) do |file|
        file.write(zones.to_json)
      end

      id
    end

    def tmp_file(id)
      dir = Rails.root.join("tmp", "zones")
      unless File.directory?(dir)
        FileUtils.mkdir(dir)
      end
      dir.join("import_" + id + ".json")
    end

    def authorize_project
      authorize @project, :create_zone?
    end

end