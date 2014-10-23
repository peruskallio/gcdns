# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

module GoogleApi
  module Dns
    
    class RemoteModel
      
      # Set the authorized API client in the extending classes.
      # The api client is individual for each scope, so because
      # of that we do not set it here in a general way. Each
      # implementing class should set its own @@api_client.
      @@api_client = nil # instance of Google::APIClient
      
      
      def self.initialize_helper
        @@helper = GoogleApi::ApiHelper.new(@@api_client, api_service)
      end
      
      def self.api_service
        @@api_client.discovered_api('dns', 'v1beta1')
      end
      
      # This creates an instance of the currenct class that
      # has the api record as the data provider object and
      # has all the methods available for call. Basically
      # it creates a proxy object to the API record object
      # (instance of Google::APIClient::Schema) that is
      # instance of the original class. The advantage of
      # doing this is to provide any additional methods the
      # actual class might have and also have the 
      # representation of the object to be a bit more 
      # accurate.
      def self.initialize_from(record)
        @obj = self.new
        @obj.api_record = record
        
        # Set all the instance variables to the class if the class
        # has defined some variable setters that exist in the 
        # API record object
        methods = @obj.class.instance_methods - Object.methods
        methods.each do |method|
          # Only search for setters ending with "="
          unless (method =~ /^.*=$/).nil?
            variable = method[0..method.length-2]
            @obj.send(method, record.send(variable)) if record.respond_to?(variable)
          end
        end
        
        @obj
      end
      
      def api_record=(record)
        @api_record = record
      end
      
      def method_missing(m, *args, &block)
        if @api_record.respond_to?(m.to_s)
          @api_record.send(m, *args, &block)
        else
          super
        end
      end
      
    end
    
  end
end