# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

require 'google/api_client'
require 'google/api_client/auth/file_storage_session'
require 'google/api_client/auth/service_account'

class Project < ActiveRecord::Base
  resourcify

  has_many :zone_permissions, dependent: :destroy

  validates :name, presence: true
  validates :project_key, presence: true
  validates :issuer, presence: true
  validates :keydata, presence: true

  def api_client(scopes)
    scopes = scopes.split(" ") unless scopes.kind_of?(Array)

    client = Google::APIClient.new(:application_name => 'GCDNS', :application_version => '0.0.1')

    # Where do we keep the authorization cache files.
    path = File.join(Rails.root, 'tmp', 'google-api')
    FileUtils.mkdir(path) unless File.directory?(path)

    # The identifier is a unique authorization specific string that identifies
    # different authentications from each other. I.e. different projects use
    # different identifiers to store their unique authentication in the file
    # level authentication cache. Otherwise all the project specific
    # authentications would use the same cache file which would cause issues.
    identifier = self.id.to_s + ':' + self.issuer

    file_storage = Google::APIClient::FileStorageSession.new(path, identifier, scopes)
    if file_storage.authorization.nil?
      auth = Google::APIClient::ServiceAccount.new(self.keydata, self.keypass, {
        scope: scopes,
        issuer: self.issuer
      })
      client.authorization = auth.authorize(file_storage)
    else
      client.authorization = file_storage.authorization
    end

    client
  end

  def addable_users
    User.all.select { |u| !(u.has_role?(:admin, self) || u.has_role?(:zone_manager, self)) }
  end

end
