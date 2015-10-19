ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def policy_test(options)
    if options[:policy].record.is_a?(Project)
      rejects = [:index, :show, :update, :destroy]
    else
      rejects = [:show, :create, :update, :destroy]
    end

    if options[:permit]
      permits = options[:permit].is_a?(Array) ? options[:permit] : [options[:permit]]
      permits.each do |key|
        assert options[:policy].send("#{key}?"), "#{options[:role]} should be able to #{key} a #{options[:policy].record.class.to_s}"
        rejects.delete(key)
      end
    end
    rejects.each do |key|
      assert !options[:policy].send("#{key}?"), "#{options[:role]} should not be able to #{key} a #{options[:policy].record.class.to_s}"
    end
  end
end
