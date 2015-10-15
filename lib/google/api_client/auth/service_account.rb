# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

module Google
  class APIClient

    class ServiceAccount

      def initialize(keydata, keypass, options)
        options.reverse_merge!({
          token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
          audience: 'https://accounts.google.com/o/oauth2/token'
        })

        json = JSON.parse(keydata) rescue false

        if json
          credentials = {
            signing_key: OpenSSL::PKey::RSA.new(json["private_key"]),
            issuer: json["client_email"]
          }
        else
          credentials = {
            signing_key: OpenSSL::PKCS12.new(keydata, keypass).key
          }
        end
        credentials.reverse_merge!(options)

        puts credentials.to_yaml

        @authorization = Signet::OAuth2::Client.new(credentials)
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