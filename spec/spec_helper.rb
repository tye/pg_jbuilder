require 'bundler/setup'
Bundler.setup
require File.expand_path("../dummy/config/environment", __FILE__)
require "rails/test_help"

require 'pg_jbuilder'

module PgJbuilder::TestHelpers
  class NonRailsTestDb < ActiveRecord::Base; end

  def self.included mod
    super
    if mod.respond_to?(:before)
      database_config = File.join(File.dirname(__FILE__),'..','config','database.yml')
      config = YAML.load(File.read(database_config))
      mod.around :each, without_rails: true do |example|
        old_value = PgJbuilder.connection
        pool = NonRailsTestDb.establish_connection config
        PgJbuilder.connection = lambda { pool.connection }
        example.call
        PgJbuilder.connection = old_value
      end
    end
  end
end

RSpec.configure do |config|
  config.include PgJbuilder::TestHelpers
end
