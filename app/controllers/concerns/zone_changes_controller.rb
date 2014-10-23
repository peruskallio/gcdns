class ZoneChangesController < RemoteController
  
  def index
    changes = GRemote::Changes.list(params[:zone_id])
    
    render json: {changes: changes}
  end
  
  def show
    change = GRemote::Changes.find(params[:id], params[:zone_id])
    
    render json: {change: change}
  end
  
  def create
    error = nil
    begin
      zone = GRemote::Zone.new
      zone.id = params[:zone_id]
      
      changerec = params[:change]
      
      changes = GRemote::Changes.new
      changes.zone = zone
      
      add = recordset_list(changerec[:additions])
      del = recordset_list(changerec[:deletions])
      
      changes.additions = add if add && add.length > 0
      changes.deletions = del if del && del.length > 0
      
      if !changes.additions && !changes.deletions
        error = {
          type: 'no_changes',
          message: "No changes provided within the request."
        }
      elsif !changes.save
        error = {
          type: 'save_failed',
          message: "Error during the API call." 
        }
      end
    rescue Exception => e
      error = {
        type: 'api_error',
        message: e.message
      }
      raise e
    end
    
    if error
      status = 500
      if error[:type] == 'no_changes'
        status = 400
      elsif error[:type] == 'api_error'
        status = 501
      end
      render json: {error: error}, status: status
    else
      render json: {change: changes}
    end
  end
  
  private
    
    def recordset_list(data)
      if data
        list = []
        data.each do |record|
          rset = GRemote::RecordSet.new
          rset.name = record[:name]
          rset.type = record[:type]
          rset.ttl = record[:ttl]
          rset.rrdatas = record[:datas]
          
          list.push rset
        end
        list
      end
    end
  
end