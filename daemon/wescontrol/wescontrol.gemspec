spec = Gem::Specification.new do |s|
	s.name = 'wescontrol'
	s.version = '0.2.1'
	s.summary = "WesControl daemon"
	s.description = %{WesControl daemon and related classes}
	s.files = Dir['lib/**/*.rb'] + Dir['test/**/*.rb'] + ['bin/wescontrol-daemon']
	s.require_path = 'lib'
	s.executables = ["wescontrol-daemon"]

	s.add_dependency('macaddr', '>= 1.0.0')
	s.add_dependency('json', '>= 1.2.0')
	s.add_dependency('bitpack', '>= 0.1')
	s.add_dependency('serialport', '>= 0.8.0')
	s.add_dependency('couchrest', '>= 0.33')
	s.add_dependency('eventmachine', '>= 0.12.10')
	s.add_dependency('eventmachine_httpserver', '>= 0.2.0')
	s.add_dependency('chronic', '>= 0.2.3')
	s.add_dependency('daemons', ">= 1.0.10")
	s.add_dependency('wol', ">= 0.3.3")
	s.add_dependency('sinatra', ">= 1.0")

	s.author = "Micah Wylde"
	s.email = "mwylde@wesleyan.edu"
	s.homepage = "http://www.accordion.org/"
end
