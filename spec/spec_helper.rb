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

# a version of Device that doesn't save to the DB, so we can do tests outside
# of EM
class NoSaveDevice < Wescontrol::Device
  def save changed = nil, old_val = nil
  end
end

RSpec.configure do |config|
	config.before(:each) {
		# Clear the test DB
		CouchRest.database!(TEST_DB).delete!
		CouchRest.database!(TEST_DB)
	}
end

module EMSpec
  def run_in_fiber( run_options )
    ($em_spec_fiber = Fiber.new{
       run_without_em( run_options )
       EM.stop_event_loop if EM.reactor_running?b
     }).resume
  end

  def run( run_options )
    EM.run do
      run_in_fiber( run_options )
    end
    true
  end

  def done
    EM.next_tick{
      :done.should == :done
      $em_spec_fiber.resume if $em_spec_fiber
    }
  end
end
