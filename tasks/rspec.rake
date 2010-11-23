begin
	require 'rspec'
	require 'rspec/core/rake_task'
rescue LoadError
	puts <<-EOS
To use rspec for testing you must install rspec gem:
    gem install rspec
EOS
end

begin
	desc "Run the specs under spec/"
	RSpec::Rake::RSpecTask.new do |t|
		t.spec_opts = ['--options', "spec/spec.opts"]
		t.spec_files = FileList['spec/**/*_spec.rb']
	end
rescue NameError
	# No loss, warning printed already
end
