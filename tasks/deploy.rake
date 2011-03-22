require 'json'

PUBLIC_KEY = true #Are we using public key authentication on all the servers?

WORKING = File.dirname(__FILE__) + '/..'

# load server addresses from servers.json
servers_file = File.open(WORKING + "/servers.json")
exit "No servers.json file found" unless servers_file
servers = JSON.parse(servers_file.read)
SERVERS = servers['servers']
CONTROLLERS = servers['controllers']
TEST = servers['test']

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
	
	puts "Hey, you're deploying to PRODUCTION!!!! Let me repeat that: PRODUCTION!!!!!!!!"
	puts "Are you absolutely, positively sure you want to do this?"
	exit(1) unless ask("Deploy? (yN) ").upcase == "Y"
	puts "Ok, but are you really, really sure?"
	exit(1) unless ask("Deploy to PRODUCTION?  (yN) ").upcase == "Y"
	
	puts "\tCreating zip of roomtrol-daemon"
	`rm /tmp/roomtrol-daemon.zip && cd #{WORKING} && zip -r /tmp/roomtrol-daemon.zip * -x .\*`
	
	CONTROLLERS.each do |controller|
		Net::SSH.start(controller, 'roomtrol', :password => OPTS[:password]) do |ssh|
			puts ssh.exec!("echo '#{OPTS[:password]}' | sudo -S mkdir /var/roomtrol-daemon && chown roomtrol /var/roomtrol-daemon")
		end
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
				"rm -Rf !(roomtrol-daemon.zip)",
				"unzip roomtrol-daemon.zip",
				"rm roomtrol-daemon.zip",
				"echo 'Unzipped zip file'",
				"rvm 1.9.2",
				"echo 'Switched to rvm'",
				"bundle install"
			]
		  
			puts ssh.exec!(commands.join("; "))
			
			puts "Restarting daemon"
			puts ssh.exec!("echo '#{OPTS[:password]}' | sudo -S restart roomtrol-daemon")
			
		end
		puts "\tInstallation finished on #{controller}"
	end
end

desc "deploy server code to tests"
task :deploy_test, :needs => [:collect_password] do
	begin
		require 'net/ssh'
		require 'net/scp'
	rescue LoadError => e
		puts "\n ~ FATAL: net-scp gem is required.\n          Try: rake install_gems"
		exit(1)
	end
	
	puts "\tCreating zip of roomtrol-daemon"
	`rm /tmp/roomtrol-daemon.zip; cd #{WORKING} && zip -r /tmp/roomtrol-daemon.zip * -x .\*`
	
	TEST.each do |controller|
		puts "Deploying to controller #{controller}"
		Net::SSH.start(controller, 'roomtrol', :password => OPTS[:password]) do |ssh|
			puts ssh.exec!("echo '#{OPTS[:password]}' | sudo -S mkdir /var/roomtrol-daemon && chown roomtrol /var/roomtrol-daemon")
		end
		Net::SCP.start(controller, 'roomtrol', :password => OPTS[:password]) do |scp|
			local_path = "/tmp/roomtrol-daemon.zip"
			remote_path = "/tmp"
			puts "\tCopying roomtrol-daemon to #{controller}"
			scp.upload! local_path, remote_path, :recursive => false
		end
		Net::SSH.start(controller, "roomtrol", :password => OPTS[:password]) do |ssh|
			puts "\tInstalling gems on server"
			path = "/var/roomtrol-daemon"
			commands = [
				"cd #{path}",
				"rm -Rf *",
				"mv /tmp/roomtrol-daemon.zip .",
				"unzip roomtrol-daemon.zip",
				"rm roomtrol-daemon.zip",
				"echo 'Unzipped zip file'",
				"echo 'Updated roomtrol' | wall",
				"rvm 1.9.2",
				"echo 'Switched to rvm'"
#				"echo '#{OPTS[:password]}' | rvmsudo -S bundle install"
			]
		  
			puts ssh.exec!(commands.join("; "))
			
			puts "Restarting daemon"
#			puts ssh.exec!("echo '#{OPTS[:password]}' | sudo -S restart roomtrol-daemon")
			
		end
		puts "\tInstallation finished on #{controller}"
	end
end
