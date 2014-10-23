# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

module Google
  class APIClient
    
    class ServiceAccount
      
      def initialize(keydata, keypass, options)
        key = OpenSSL::PKCS12.new(keydata, keypass).key
        @authorization = Signet::OAuth2::Client.new({
          signing_key: key,
          token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
          audience: 'https://accounts.google.com/o/oauth2/token'
        }.update(options))
      end
      
      def authorize(storage=nil)
        @authorization.fetch_access_token!
        
        if storage.respond_to?(:write_credentials)
          storage.write_credentials(@authorization)
        end
        
        @authorization
      end
      
    end
  end
end