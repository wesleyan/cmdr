spec = Gem::Specification.new do |s|
	s.name = 'WesControl'
	s.version = '0.1.0'
	s.summary = "WesControl daemon"
	s.description = %{WesControl daemon and related classes}
	s.files = Dir['lib/**/*.rb'] + Dir['test/**/*.rb']
	s.require_path = 'lib'
	#s.autorequire = 'builder'
	#s.extra_rdoc_files = Dir['[A-Z]*']
	#s.rdoc_options << '--title' <<  'Builder -- Easy XML Building'
	s.author = "Micah Wylde"
	s.email = "mwylde@wesleyan.edu"
	s.homepage = "http://www.accordion.org/"
end
