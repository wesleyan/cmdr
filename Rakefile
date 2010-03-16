require 'extlib'

WORKING = File.dirname(__FILE__)
TARGETS = ['/tp5']

SERVERS = ["129.133.124.142"]

OPTS = {}

$:
desc "Builds sc apps for deployment"
task :build do
	Dir.chdir WORKING / 'wescontrol_web'
	puts `sc-build #{TARGETS * ' '} -rv`
end

desc "cleans the build output"
task :clean do
	path = WORKING / 'wescontrol_web' / 'tmp' / 'build' / 'production' / 'static'
	puts "Removing #{path}"
	puts `rm -r #{path}`
end

desc "installs gems needed for this Rakefile to run"
task :install_gems do
	puts "sudo gem install highline net-ssh net-scp sproutit-sproutcore"
	puts `sudo gem install highline net-ssh net-scp sproutit-sproutcore`
end

desc "collects the login password from the operator"
task :collect_password do
	begin
		require 'highline/import'
	rescue LoadError => e
	    puts "\n ~ FATAL: sproutcore gem is required.\n          Try: rake install_gems"
	    exit(1)
	end
	
	puts "Enter wescontrol password to complete this task"
	OPTS[:password] = ask("Password: "){|q| q.echo = '*'}
end

desc "finds all targets in the system and computes their build numbers" 
task :prepare_targets do
	begin
		require 'sproutcore'  
	rescue LoadError => e
		puts "\n ~ FATAL: sproutcore gem is required.\n          Try: rake install_gems"
		exit(1)
	end

	puts "discovering all installed targets"
	SC.build_mode = :production
	project = SC.load_project(WORKING/'wescontrol_web') 

	# get all targets and prepare them so that build numbers work
	targets = TARGETS.map do |name| 
		target = project.target_for(name)
		[target] + target.expand_required_targets
	end
	targets = targets.flatten.compact.uniq

	puts "preparing build numbers"
	targets.each { |t| t.prepare!.compute_build_number }

	OPTS[:targets] = targets
	OPTS[:project] = project
end


desc "copies the files to the servers"
task :deploy_assets => [:collect_password, :build, :prepare_targets] do
	begin
		require 'net/ssh'
		require 'net/scp'
	rescue LoadError => e
		puts "\n ~ FATAL: net-scp gem is required.\n          Try: rake install_gems"
		exit(1)
	end
	
	password = OPTS[:password]
	targets  = OPTS[:targets]

	SERVERS.each do |server|
		installed = {}
		puts "building directory structure on #{server}"
		Net::SSH.start(server, 'wescontrol', :password => password) do |ssh|
			targets.each do |target|
				remote_path = "/var/www/static#{target.index_root}/en"
				puts ssh.exec!(%[mkdir -p "#{remote_path}"]) || "%: mkdir -p #{remote_path}"
				
				remote_path = "#{remote_path}/#{target.build_number}"
				installed[remote_path] = !(ssh.exec!("ls #{remote_path}") =~ /No such file or directory/)
			end
		end
		
		puts "Copying static resources onto #{server}"
		Net::SCP.start(server, 'wescontrol', :password => password) do |scp|
			targets.each do |target|
				local_path = target.build_root / 'en' / target.build_number
				remote_path = "/var/www/static#{target.index_root}/en"
				short_path = local_path.gsub /^#{Regexp.escape(target.build_root)}/,''
				if installed["#{remote_path}/#{target.build_number}"]
					puts " ~ #{target.target_name}#{short_path} already installed"
				elsif File.directory?(local_path)
					puts " ~ uploading #{target.target_name}#{short_path}"
					scp.upload! local_path, remote_path, :recursive => true
				else
					puts "\n\n ~ WARN: cannot install #{target.target_name} - local path #{local_path} does not exist\n\n"
				end
			end
		end
	end
end

desc "creates symlinks to the latest versions of all pages and apps. Make sure you deploy your assets also!"
task :link_current => [:collect_password, :prepare_targets] do
 
	# don't require unless this task runs to avoid dependency problems
	begin
		require 'net/ssh'
	rescue LoadError => e
		puts "\n ~ FATAL: net-ssh gem is required.\n          Try: rake install_gems"
		exit(1)
	end
    
	# now filter out only app targets living in the current project
	targets = OPTS[:targets]
	project = OPTS[:project]
	targets = targets.select { |t| t.target_type == :app }
	targets = targets.select do |t| 
		t.source_root =~ /^#{Regexp.escape(project.project_root)}/
	end

	puts "linking targets:\n  #{targets.map {|t| t.target_name} * "\n  " }"

	# SSH in and do the symlink
	password = OPTS[:password]
	SERVERS.each do |server|
		Net::SSH.start(server, "wescontrol", :password => password) do |ssh|
			targets.each do |target|
			# find the local build number
				build_number = target.prepare!.compute_build_number

				puts "Installing #{target.target_name} to #{server}..."

				# first, link index.html
				from_path = "/var/www/static#{target.index_root}/en/#{build_number}/index.html"
				to_path   = "/var/www#{target.target_name}"

				puts ssh.exec!("mkdir -p #{to_path}") || "% mkdir -p #{to_path}"
				to_path = "#{to_path}/index.html"
				unless ssh.exec!("ls #{to_path}").empty? # check for existance
					puts ssh.exec!("rm #{to_path}") || " ~ Removed link at #{to_path}"
				end
				puts ssh.exec!("ln -s #{from_path} #{to_path}") || " ~ Linked #{from_path} => #{to_path}"

				# link each language
				from_path = "/var/www/static#{target.index_root}/en/#{build_number}"
				to_path   = "/var/www#{target.target_name}/en"

				unless ssh.exec!("ls #{to_path}").empty? # check for existance
					puts ssh.exec!("rm #{to_path}") || " ~ Removed link at #{to_path}"
				end
				puts ssh.exec!("ln -s #{from_path} #{to_path}") || " ~ Linked #{from_path} => #{to_path}"
			end
		end
	end
end

desc "builds and then deploys the files to the server.  This will not clean the build first, which will be faster.  If you have trouble try deploy_clean"
task :deploy => [:collect_password, :build, :deploy_assets, :link_current]
 
desc "first cleans, then deploys the files"
task :deploy_clean => [:clean, :deploy]

