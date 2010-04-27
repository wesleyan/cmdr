require 'ping'
require 'wol'

class Computer < Wescontrol::Device
	@interface = "Computer"
	
	config_var :ip_address
	config_var :mac_address
	#attempt to turn on the computer via WoL
	command :start, :action => proc{
		w = Wol::WakeOnLan.new(:address => self.ip_address, :mac => self.mac_address)
		w.wake
	}
	
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

#126.184