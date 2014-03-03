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
		t.files   = ['lib/**/*.rb']  # optional
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
		unless Dir.exists? "cmdr-daemon.wiki"
			Git.clone('git@github.com:mwylde/cmdr-daemon.wiki.git', 'cmdr-daemon.wiki')
		end

		File.open "cmdr-daemon.wiki/Device.md", "w+" do |f|
			YARD.parse('lib/cmdr/device.rb')
			f.write YARD::Registry.objects["Cmdr::Device"].docstring
		end
		
		File.open "cmdr-daemon.wiki/RS232Device.md", "w+" do |f|
			YARD.parse('lib/cmdr/RS232Device.rb')
			f.write YARD::Registry.objects["Cmdr::RS232Device"].docstring
		end

		g = Git.open('cmdr-daemon.wiki')
		g.add('Device.md')
		g.add('RS232Device.md')
		g.commit("Updated Device")
		g.push
		puts "Updated device on wiki"
	end
rescue NameError
	# No loss, warning printed already
end

