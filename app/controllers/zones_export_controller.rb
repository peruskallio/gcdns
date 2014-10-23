# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

class ZonesExportController < RemoteController
  
  before_action :set_project, only: [:index, :create, :process_zone, :process_done]
  skip_before_action :verify_authenticity_token, only: [:process_zone]
  
  def index
    @zones = GRemote::Zone.list
  end
  
  def create
    @zones = params[:zone]
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
    
    if zones && zones.length > 0 && zones.include?(zone)
      # Order the records in the following order.
      record_order = ["SOA", "NS", "A", "AAAA", "CNAME", "MX", "SPF", "SRV", "TXT"]
      
      begin
        zonefile = ""
        
        zone = GRemote::Zone.find(zone)
        
        # First we want to sort the records properly
        records = {}
        names = []
        
        lengths = {
          name: 0,
          ttl: 0,
          type: 0
        }
        
        zone.recordsets.each do |rset|
          rttl = rset.ttl.to_s
          rttl = "" if rttl == ttl
          
          name = rset.name
          if name == zone.dns_name
            # domain.com. => @
            name = '@'
          elsif name.end_with?("." + zone.dns_name)
            # E.g. subdomain.domain.com. => subdomain
            name = name[0, name.length - zone.dns_name.length - 1]
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
        zonefile += "\n$ORIGIN " + zone.dns_name
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