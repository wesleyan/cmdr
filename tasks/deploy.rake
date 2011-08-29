require 'highline'
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

HIGHLINE = HighLine.new

desc "deploy server code"
task :deploy do
	puts "Hey, you're deploying to PRODUCTION!!!! Let me repeat that: PRODUCTION!!!!!!!!"
	puts "Are you absolutely, positively sure you want to do this?"
	exit(1) unless HIGHLINE.ask("Deploy? (yN) ").upcase == "Y"
	puts "Ok, but are you really, really sure?"
	exit(1) unless HIGHLINE.ask("Deploy to PRODUCTION?  (yesNO) ").upcase == "YES"

  deploy SERVERS
end

desc "deploy server code to tests"
task :deploy_test  do
  deploy TEST
end

def deploy servers
  begin
		require 'net/ssh'
		require 'net/scp'
	rescue LoadError => e
		puts "\n ~ FATAL: net-scp gem is required.\n          Try: rake install_gems"
		exit(1)
	end
	
	puts "\tCreating zip of roomtrol-daemon"
	`rm /tmp/roomtrol-daemon.zip`
  `cd #{WORKING} && zip -r /tmp/roomtrol-daemon.zip * -x .\*`
	
	servers.each do |controller|
		puts "Deploying to controller #{controller}"
		Net::SSH.start(controller, 'roomtrol', :password => OPTS[:password]) do |ssh|
			puts ssh.exec!("if [ ! -d /var/roomtrol-daemon ]; then sudo mkdir /var/roomtrol-daemon; fi; sudo chown roomtrol /var/roomtrol-daemon")
		end
		Net::SCP.start(controller, 'roomtrol', :password => OPTS[:password]) do |scp|
			local_path = "/tmp/roomtrol-daemon.zip"
			remote_path = "/tmp"
			puts "Copying roomtrol-daemon to #{controller}"
			scp.upload! local_path, remote_path, :recursive => false
		end
		Net::SSH.start(controller, "roomtrol", :password => OPTS[:password]) do |ssh|
			puts "Installing gems on server"
			path = "/var/roomtrol-daemon"
			commands = [
                  "echo 'starting'",
                  "cd #{path}",
                  "rm -Rf *",
                  "mv /tmp/roomtrol-daemon.zip .",
                  "unzip -q roomtrol-daemon.zip",
                  "rm roomtrol-daemon.zip",
                  "echo 'Unzipped zip file'",
                  "rvm 1.9.2",
                  "echo 'Switched to rvm'",
                  "sudo bundle install",
                  "echo 'Updated roomtrol' | wall",
                 ]
		  
			puts ssh.exec!(commands.join("; "))
			
			puts "Restarting daemon"
			puts ssh.exec!("sudo restart roomtrol-daemon")
			
		end
		puts "\tInstallation finished on #{controller}"
	end
end
