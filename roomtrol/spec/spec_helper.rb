DAEMON_ENV = 'test' unless defined?( DAEMON_ENV )

begin
	require 'spec'
	require 'mq'
rescue LoadError
	require 'rubygems'
	gem 'rspec'
	require 'spec'
end

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

Spec::Runner.configure do |config|
	
	# == Mock Framework
	#
	# RSpec uses it's own mocking framework by default. If you prefer to
	# use mocha, flexmock or RR, uncomment the appropriate line:
	#
	# config.mock_with :mocha
	# config.mock_with :flexmock
	# config.mock_with :rr
end
