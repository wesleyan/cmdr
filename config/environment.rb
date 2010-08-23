$eventmachine_library = :pure_ruby

# Be sure to restart your daemon when you modify this file

# Uncomment below to force your daemon into production mode
#ENV['DAEMON_ENV'] ||= 'production'

# Boot up
require_relative 'boot'

DaemonKit::Initializer.run do |config|

	# The name of the daemon as reported by process monitoring tools
	config.daemon_name = 'roomtrol'

	# Force the daemon to be killed after X seconds from asking it to
	config.force_kill_wait = 15

	# Log backraces when a thread/daemon dies (Recommended)
	config.backtraces = true

	# Configure the safety net (see DaemonKit::Safety)
	# config.safety_net.handler = :mail # (or :hoptoad )
	config.safety_net.handler = :mail
	#config.safety_net.mail.host = 'localhost'
	
	if File.writable?("/var/log") #are we root?
		config.log_path = "/var/log/roomtrol.log"
	else
		unless File.directory?(File.expand_path "~/log")
			require 'fileutils'
			FileUtils.mkdir(File.expand_path "~/log")
		end
		config.log_path = File.expand_path "~/log/roomtrol.log"
	end
end
