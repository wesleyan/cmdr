require 'ping'

class Computer < Wescontrol::Device
	@interface = "Computer"
	
	config_var :ip_address
	
	#current info
	state_var :reachable, 		:kind => :boolean, 	:editable => false
	
	def initialize(options)
		@ip_address = options[:ip_address]
		super(options)
		
		Thread.new {
			while true
				self.reachable = Ping.pingecho(self.ip_address)
				sleep 5
			end
		}
		
	end
	
end
