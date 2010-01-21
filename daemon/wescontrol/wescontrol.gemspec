spec = Gem::Specification.new do |s|
	s.name = 'wescontrol'
	s.version = '0.1.1'
	s.summary = "WesControl daemon"
	s.description = %{WesControl daemon and related classes}
	s.files = Dir['lib/**/*.rb'] + Dir['test/**/*.rb']
	s.require_path = 'lib'

	s.add_dependency('macaddr', '>= 1.0.0')
	s.add_dependency('json', '>= 1.2.0')
	s.add_dependency('bitpack', '>= 0.1')
	s.add_dependency('serialport', '>= 0.8.0')
	s.add_dependency('couchrest', '>= 0.33')
	s.add_dependency('eventmachine', '>= 0.12.10')
	s.add_dependency('eventmachine_httpserver', '>= 0.2.0')

	#s.autorequire = 'builder'
	#s.extra_rdoc_files = Dir['[A-Z]*']
	#s.rdoc_options << '--title' <<  'Builder -- Easy XML Building'
	s.author = "Micah Wylde"
	s.email = "mwylde@wesleyan.edu"
	s.homepage = "http://www.accordion.org/"
end
