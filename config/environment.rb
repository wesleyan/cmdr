# Be sure to restart your daemon when you modify this file

# Uncomment below to force your daemon into production mode
#ENV['DAEMON_ENV'] ||= 'production'

# Boot up
require_relative 'boot'

DaemonKit::Initializer.run do |config|

	# The name of the daemon as reported by process monitoring tools
	config.daemon_name = 'cmdr'

	# Force the daemon to be killed after X seconds from asking it to
	config.force_kill_wait = 15

	# Log backraces when a thread/daemon dies (Recommended)
	config.backtraces = true

	# Configure the safety net (see DaemonKit::Safety)
	# config.safety_net.handler = :mail # (or :hoptoad )
	config.safety_net.handler = :mail
	#config.safety_net.mail.host = 'localhost'
	
	if File.writable?("/var/log") #are we root?
		config.log_path = "/var/log/cmdr.log"
    config.pid_file = "/var/log/cmdr.pid"
	else
		unless File.directory?(File.expand_path "~/log")
			require 'fileutils'
			FileUtils.mkdir(File.expand_path "~/log")
		end
		config.log_path = File.expand_path "~/log/cmdr.log"
    config.pid_file = File.expand_path "~/log/cmdr.pid"
	end
end
