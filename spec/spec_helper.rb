require 'eventmachine'

TEST_DB_HOST = "localhost"
TEST_DB_PORT = 5984
TEST_DB_NAME = "rooms_test"
TEST_DB = "http://#{TEST_DB_HOST}:#{TEST_DB_PORT}/#{TEST_DB_NAME}"

DAEMON_ENV = 'test' unless defined?( DAEMON_ENV )

begin
	require 'rspec'
rescue LoadError
	require 'rubygems'
	gem 'rspec'
	require 'rspec'
end

require 'mq'

require_relative '../lib/roomtrol/device.rb'
require_relative '../lib/roomtrol/constants.rb'

#require File.dirname(__FILE__) + '/../config/environment'
#DaemonKit::Application.running!

DEBUG = 1
class DaemonKit
	def self.logger
		return Logger
	end
	class Logger
		def self.debug x
			puts "Debug: #{x}" if DEBUG > 2
		end
		def self.info x
			puts "Log: #{x}" if DEBUG > 1
		end
		def self.error x
			puts "Error: #{x}" if DEBUG > 0
		end
		def self.exception x
			puts "Exception: #{x}"
		end
	end
end

class Wescontrol::Device
	# We change the default db_uri to the test database, so that we don't
	# insert fake data into the real database
	def new_initialize name, hash = {}, db_host = TEST_DB_HOST, db_port = TEST_DB_PORT, db_name = TEST_DB_NAME, dqueue = nil
		if dqueue
			old_initialize(name, hash, db_host, db_port, db_name, dqueue)
		else
			old_initialize(name, hash, db_host, db_port, db_name)
		end
	end
	alias_method :old_initialize, :initialize
	alias_method :initialize, :new_initialize
end

RSpec.configure do |config|
	config.before(:each) {
		# Clear the test DB
		CouchRest.database!(TEST_DB).delete!
		CouchRest.database!(TEST_DB)
	}
	
	
	# == Mock Framework
	#
	# RSpec uses it's own mocking framework by default. If you prefer to
	# use mocha, flexmock or RR, uncomment the appropriate line:
	#
	# config.mock_with :mocha
	# config.mock_with :flexmock
	# config.mock_with :rr
end
