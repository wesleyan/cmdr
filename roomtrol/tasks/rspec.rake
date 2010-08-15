begin
	require 'spec'
	require 'spec/rake/spectask'
	#require 'moqueue'
rescue LoadError
	puts <<-EOS
To use rspec for testing you must install rspec gem:
    gem install rspec
We also use the moqueue gem for mocking an AMQP broker
	gem install moqueue
EOS
end

begin
	desc "Run the specs under spec/"
	Spec::Rake::SpecTask.new do |t|
		t.spec_opts = ['--options', "spec/spec.opts"]
		t.spec_files = FileList['spec/**/*_spec.rb']
	end
rescue NameError
	# No loss, warning printed already
end
