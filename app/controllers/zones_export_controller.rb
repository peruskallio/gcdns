# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

class ZonesExportController < RemoteController

  before_action :set_project, only: [:index, :create, :process_zone, :process_done]
  skip_before_action :verify_authenticity_token, only: [:process_zone]

  def index
    # @zones = current_user.allowed_zones(GRemote::Zone.list, @project, :read)
    @zones = current_user.allowed_zones(GRemote::Zone.list, @project, :read)
  end

  def create
    @zones = params[:zone]
    authorize_zones(@zones)
    ttl = params[:ttl].strip

    if @zones.length < 1
      flash[:alert] = "You need to select at least one zone to export."
      return redirect_to action: "index"
    end
    unless /\d+/ =~ ttl
      flash[:alert] = "Invalid default TTL."
      return redirect_to action: "index"
    end

    @id = save_data({
      zones: @zones,
      ttl: ttl,
      zonefiles: {}
    })
  end

  def process_zone
    errors = []
    data_id = params[:export_id]
    data = fetch_data(data_id)
    ttl = data["ttl"] ? data["ttl"] : "21600"
    zones = data["zones"] if data
    zone = params[:zone]

    authorize_zones(zones)

    if zones && zones.length > 0 && zones.include?(zone)
      begin
        zone = GRemote::Zone.find(zone)
        zonefile = zone.export(ttl)
        # Save zonefile
        data["zonefiles"][zone.dns_name] = zonefile
        save_data(data, data_id)
      rescue Exception => e
        errors.push(e.message)
      end
    else
      errors.push("Invalid zone provided for export.")
    end

    if errors.length > 0
      render json: {success: 0, errors: errors}
    else
      render json: {success: 1}
    end
  end

  def process_done
    data_id = params[:export_id]
    data = fetch_data(data_id)

    error = false
    if data
      @export_data = ""

      data["zonefiles"].each do |dns_name, zone_data|
        if @export_data.length > 0
          @export_data += "\n\n"
        end
        @export_data += ";; ZONE: " + dns_name + " ;;\n"
        @export_data += zone_data
      end

      # Clear the data file.
      begin
        clear_data(data_id)
      rescue Exception => e
        error = true
        flash[:alert] = e.message
      end
    else
      error = true
      flash[:alert] = "Could not load the export data."
    end

    if error
      redirect_to action: "index"
    end
  end

  private

    def authorize_zones(zones)
      zones.each do |zone_id|
        zone = GRemote::Zone.new
        zone.id = zone_id
        authorize(zone, :show?)
      end
    end

    # This is a bit redundant  with the import controller.
    # TODO: Refactor these into their own module
    def fetch_data(id)
      data = nil
      begin
        data = JSON.load(File.open(data_file(id), 'r') { |f| f.read })
      rescue
      end
      data
    end

    def clear_data(id)
      file = data_file(id)
      File.delete(file) if File.exist?(file)
    end

    def save_data(data, id = nil)
      # Create random ID for the saved data.
      id = SecureRandom.hex(16) if id.nil?

      # And save it
      File.open(data_file(id), 'w', 0600) do |file|
        file.write(data.to_json)
      end

      id
    end

    def data_file(id)
      dir = Rails.root.join("tmp", "zones")
      unless File.directory?(dir)
        FileUtils.mkdir(dir)
      end
      dir.join("export_" + id + ".json")
    end

end