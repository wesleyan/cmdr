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
rescue NameError
	# No loss, warning printed already
end

