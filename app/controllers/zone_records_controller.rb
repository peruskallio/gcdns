# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

class ZoneRecordsController < RemoteController
  
  # We want to return both the zone and the records for that zone
  # within the same request so that we can avoid calling the API
  # twice and thus, speeding up the whole fetching process.
  def index
    error = nil
    begin
      @zone = GRemote::Zone.find(params[:zone_id])
    rescue Exception => e
      error = e.message
    end
    
    if error
      render json: {error: error}
    else
      # Which key names should be changed for records?
      record_keys = {"rrdatas" => "datas"}
      
      idnum = 1
      record_ids = []
      records = @zone.recordsets.map {|item|
        hash = item.to_hash
        hash.keys.each {|k|
          if key = record_keys[k]
            hash[key] = hash[k]
            hash.delete(k)
          end
        }
        hash["id"] = idnum
        #hash["zone"] = @zone.id
        record_ids.push(idnum)
        idnum += 1
        hash.except("kind")
      }
      
      #.merge({"records" => record_ids})
      render json: {
        zones: [@zone.to_hash.select {|k,v| ["id", "name", "description", "dnsName"].include?(k) }],
        records: records
      }
    end
  end
  
  
end