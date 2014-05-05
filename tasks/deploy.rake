require 'highline'
require 'json'
require 'slinky'
require 'pty'
require 'expect'

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

desc "build touchscreen interface"
task :build_tp do
  `rm -rf #{WORKING}/tp6/pub`
  `cd #{WORKING}/tp6/src && slinky build -o #{WORKING}/tp6/pub && cat #{WORKING}/tp6/pub/tp6.html > #{WORKING}/tp6/pub/tp6 && cat #{WORKING}/tp6/pub/tp6_remote.html > #{WORKING}/tp6/pub/tp6_remote`
  `sed -i '' -e 's/\\/scripts.js/..\\/scripts.js/; s/\\/styles.css/..\\/styles.css/' #{WORKING}/tp6/pub/tp6`
  `sed -i '' -e 's/\\/scripts.js/..\\/scripts.js/; s/\\/styles.css/..\\/styles.css/' #{WORKING}/tp6/pub/tp6_remote`
  # Slinky::Builder.build(WORKING + "/tp6/src", WORKING + "/tp6/pub")
end

desc "deploy touchscreen interface"
task :deploy_tp, [] => [:build_tp] do
  CONTROLLERS.each{|c|
    cmd = "rsync -arvz -e ssh #{WORKING}/tp6/pub/ cmdr@#{c}:/var/www/tp6 --exclude '.git' --exclude 'tp6.html' 2>&1"
    system(cmd)
    `ssh cmdr@#{c} 'sudo chmod 0755 /var/www/tp6/cgi-bin/*.cgi'`
  }
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
	
	puts "\tCreating zip of cmdr-daemon"
	`rm /tmp/cmdr-daemon.zip`
  `cd #{WORKING} && zip -r /tmp/cmdr-daemon.zip * -x .\*`
	
	servers.each do |controller|
		puts "Deploying to controller #{controller}"
		Net::SSH.start(controller, 'cmdr', :password => OPTS[:password]) do |ssh|
			puts ssh.exec!("if [ ! -d /var/cmdr-daemon ]; then sudo mkdir /var/cmdr-daemon; fi; sudo chown cmdr /var/cmdr-daemon")
		end
		Net::SCP.start(controller, 'cmdr', :password => OPTS[:password]) do |scp|
			local_path = "/tmp/cmdr-daemon.zip"
			remote_path = "/tmp"
			puts "Copying cmdr-daemon to #{controller}"
			scp.upload! local_path, remote_path, :recursive => false
		end
		Net::SSH.start(controller, "cmdr", :password => OPTS[:password]) do |ssh|
			puts "Installing gems on server"
			path = "/var/cmdr-daemon"
			commands = [
                  "echo 'starting'",
                  "cd #{path}",
                  "rm -Rf *",
                  "mv /tmp/cmdr-daemon.zip .",
                  "unzip -q cmdr-daemon.zip",
                  "rm cmdr-daemon.zip",
                  "echo 'Unzipped zip file'"]
		  
			puts ssh.exec!(commands.join("; "))

      env = ['PATH="/usr/local/rvm/gems/ruby-2.1.1/bin:/usr/local/rvm/gems/ruby-2.1.1@global/bin:/usr/local/rvm/rubies/ruby-2.1.1/bin:/usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:$PATH"',
        
             'GEM_HOME="/usr/local/rvm/gems/ruby-2.1.1"',
             'GEM_PATH="/usr/local/rvm/gems/ruby-2.1.1:/usr/local/rvm/gems/ruby-2.1.1@global"',
             'BUNDLE_GEMFILE="/var/cmdr-daemon/Gemfile"',
             'TERM=xterm',
             'RUBY_VERSION=ruby-2.1.1'
            ]
      

      puts ssh.exec!("#{env.join(" ")} rvmsudo bundle install")
			puts "Restarting daemon"
			puts ssh.exec!("sudo restart cmdr-daemon")
			
		end
		puts "\tInstallation finished on #{controller}"
	end
end
