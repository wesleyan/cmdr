require 'json'

PUBLIC_KEY = false #Are we using public key authentication on all the servers?

WORKING = File.dirname(__FILE__) + '/..'

# load server addresses from servers.json
servers_file = File.open(WORKING + "/servers.json")
exit "No servers.json file found" unless servers_file
servers = JSON.parse(servers_file.read)
SERVERS = servers['servers']
CONTROLLERS = servers['controllers']

OPTS = {}


desc "installs gems needed for this Rakefile to run"
task :install_gems do
	puts "sudo gem install highline net-ssh net-scp git"
	puts `sudo gem install highline net-ssh net-scp git`
end

desc "collects the login password from the operator"
task :collect_password do
	unless PUBLIC_KEY
		begin
			require 'highline/import'
		rescue LoadError => e
		    puts "\n ~ FATAL: highline gem is required.\n          Try: rake install_gems"
		    exit(1)
		end
	
		puts "Enter roomtrol password to complete this task"
		OPTS[:password] = ask("Password: "){|q| q.echo = '*'}
	end
end

desc "deploy server code"
task :deploy, :needs => [:collect_password] do
	begin
		require 'net/ssh'
		require 'net/scp'
	rescue LoadError => e
		puts "\n ~ FATAL: net-scp gem is required.\n          Try: rake install_gems"
		exit(1)
	end
	
	puts "\tCreating zip of roomtrol-daemon"
	`rm /tmp/roomtrol-daemon.zip && cd #{WORKING} && zip -r /tmp/roomtrol-daemon.zip * -x .\*`
	
	CONTROLLERS.each do |controller|
		Net::SCP.start(controller, 'roomtrol', :password => OPTS[:password]) do |scp|
			local_path = "/tmp/roomtrol-daemon.zip"
			remote_path = "/var/roomtrol-daemon"
			puts "\tCopying roomtrol-daemon to #{controller}"
			scp.upload! local_path, remote_path, :recursive => false
		end
		Net::SSH.start(controller, "roomtrol", :password => OPTS[:password]) do |ssh|
			puts "\tInstalling gems on server"
			path = "/var/roomtrol-daemon"
			commands = [
				"cd #{path}",
				"unzip roomtrol-daemon.zip",
				"rm roomtrol-daemon.zip"
			]
		  
			puts ssh.exec!(commands.join("; "))
		end
		puts "\tInstallation finished on #{controller}"
	end
end