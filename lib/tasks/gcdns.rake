# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

namespace :gcdns do
  desc "Creates a new user. Pass in email and password as the rake task parameters."
  task :create_user, [:email, :password] => [:environment] do |t, args|
    @user = User.new(email: args[:email], password: args[:password], password_confirmation: args[:password])
    @user.save!
  end
end