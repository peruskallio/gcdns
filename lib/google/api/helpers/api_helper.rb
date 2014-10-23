# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

module GoogleApi
  
  class ApiHelper
    
    def initialize(api_client, api_service)
      @api_client = api_client
      @api_service = api_service
    end
    
    def api_call
      yield @api_service
    end
    
    def api_request(method, parameters=nil, body=nil)
      request = Google::APIClient::Request.new({
        api_client: @api_client,
        api_method: method,
        parameters: parameters,
        body_object: body
      })
      result = @api_client.execute(request)
      
      if result.nil? || result.data.nil?
        # Might also be because of incorrect parameters passed to the API.
        # If this is the case, the API might not return the "data" has.
        raise InvalidRecordError.new(result), "Invalid record returned by the API."
      elsif result.data["error"]
        raise ErrorStateError.new(result), result.data["error"]["message"]
      end
      
      result
    end
    
  end
  
end