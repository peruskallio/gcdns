# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

module Google
  class APIClient
    
    # This is different than the original Google::APIClient::FileStorage
    # because this also stores authentications that do not contain a
    # refresh token. This is used to authenticate the clients within
    # the same session.
    
    class FileStorageSession
      
      # The cache implementation is largely based on the one in the google-api-client gem.
      # The version of the gem where these are from is 0.7.1.
      # The borrowed parts are from the Google::APIClient::KeyUtils class.
      # Attribution for these go to the original author, Steve Bazyl (GitHub: @sqrrrl).
      # The implementation is modified from the original source files to fit this project
      # but the implementation method is the same.
      
      # @return [String] Path to the credentials file.
      attr_accessor :path

      # @return [Signet::OAuth2::Client] Path to the credentials file.
      attr_reader :authorization
      
      def initialize(path, identifier, scopes)
        @path = path
        @identifier = identifier
        @scopes = scopes
      end
      
      def load_credentials
        creds_file = cache_file
        if File.exist? creds_file
          authorization = nil
          File.open(creds_file, 'r') do |file|
            cached_credentials = JSON.load(file)
            @authorization = Signet::OAuth2::Client.new(cached_credentials)
            @authorization.issued_at = Time.at(cached_credentials['issued_at'])
          end
          # The authorization does not contain a refresh token,
          # for some undocumented reason, so when it is expired,
          # we need to create a new one.
          if @authorization && @authorization.expired?
            @authorization = nil
          end
        end
      end
      
      def write_credentials(authorization)
        @authorization = authorization unless authorization.nil?
        
        hash = {}
        %w'access_token
         authorization_uri
         client_id
         client_secret
         expires_in
         refresh_token
         token_credential_uri'.each do |var|
          hash[var] = @authorization.instance_variable_get("@#{var}")
        end
        hash['issued_at'] = @authorization.issued_at.to_i
        
        creds_file = cache_file
        File.open(creds_file, 'w', 0600) do |file|
          file.write(hash.to_json)
        end
      end
      
      def clear_credentials
        creds_file = cache_file
        File.delete(creds_file) if File.exist?(creds_file)
      end
      
      private
        
        def cache_file
          File.join(@path, 'googleapi-' + Digest::MD5.hexdigest(@identifier + ':' + @scopes.join(" ")) + '.json')
        end
        
    end
  end
end