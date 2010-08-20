begin
	require 'yard'
rescue LoadError
	puts <<-EOS
To generate docs you must install the YARDoc gem, as well as bluecloth (for markdown):
    gem install yard bluecloth
EOS
end

begin
	desc "Generate the docs"
	YARD::Rake::YardocTask.new do |t|
		t.files   = ['lib/**/*.rb', 'lib/**/**/.rb']   # optional
		t.options = ['--markup', 'markdown', '--no-private'] # optional
	end
	
	desc "Update wiki with newest docs"
	task :wiki_docs do
		begin
			require 'git'
			require 'yard'
		rescue LoadError => e
			puts "\n ~ FATAL: ruby-git gem is required.\n          Try: rake install_gems"
			exit(1)
		end

		#If the wiki is not checked out, check it out
		unless Dir.exists? "roomtrol-daemon.wiki"
			Git.clone('git@github.com:mwylde/roomtrol-daemon.wiki.git', 'roomtrol-daemon.wiki')
		end

		File.open "roomtrol-daemon.wiki/Device.md", "w+" do |f|
			YARD.parse('lib/roomtrol/device.rb')
			f.write YARD::Registry.objects["Wescontrol::Device"].docstring
		end

		g = Git.open('roomtrol-daemon.wiki')
		g.add('Device.md')
		g.commit("Updated Device")
		g.push
		puts "Updated device on wiki"
	end
rescue NameError
	# No loss, warning printed already
end

