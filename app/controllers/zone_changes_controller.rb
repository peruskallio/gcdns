# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

class ZoneChangesController < RemoteController

  def index
    zone = GRemote::Zone.new
    zone.id = params[:zone_id]
    authorize(zone, :show?)
    changes = GRemote::Changes.list(params[:zone_id])

    render json: {changes: changes}
  end

  def show
    zone = GRemote::Zone.new
    zone.id = params[:zone_id]
    authorize(zone, :show?)
    change = GRemote::Changes.find(params[:id], params[:zone_id])

    render json: {change: change}
  end

  def create
    error = nil
    begin
      zone = GRemote::Zone.new
      zone.id = params[:zone_id]

      authorize(zone, :edit?)

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
      elsif changes.save
        # If the SOA record was not updated during the request,
        # it needs to be updated manually in order to increment
        # the SOA serial value.
        unless add && add.any? {|rec| rec.type == 'SOA'}
          zone.update_soa
        end
      else
        error = {
          type: 'save_failed',
          message: "Error during the API call."
        }
      end
    rescue Exception => e
      if e.is_a? Pundit::NotAuthorizedError
        msg = "Insufficient credentials!"
      else
        msg = e.message
      end
      error = {
        type: 'api_error',
        message: msg
      }
      # raise e
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