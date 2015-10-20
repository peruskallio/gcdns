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

    data = params[:data] + "\n$ORIGIN empty.com."

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
      domain_dns = domain
      domain_dns += '.' unless /\.$/.match(domain)

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
        result = GRemote::Zone.import(zone_string, domain, domain_dns)
        if result[:errors].length == 0
          begin
            zone = result[:zone]
            zone.save

            changes = GRemote::Changes.new
            changes.zone = zone
            changes.additions = result[:additions]
            changes.save
            current_user.create_permissions_for_new_zone(zone)
            result[:zone].update_soa
          rescue Exception => e
            errors.push(e.message)
          end
        else
          errors = result[:errors]
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
      authorize GRemote::Zone.new, :create?
    end

end