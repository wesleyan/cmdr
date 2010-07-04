require 'ping'
require 'wol'

class Computer < Wescontrol::Device
	configure do
		ip_address :type => :string
		macc_address :type => :string
	end
	#attempt to turn on the computer via WoL
	command :start, :action => proc{
		w = Wol::WakeOnLan.new(:address => self.ip_address, :mac => self.mac_address)
		w.wake
	}
	
	#current info
	state_var :reachable, :type => :boolean, :editable => false, :display_order => 1
	
	def initialize(name, options)
		@ip_address = options[:ip_address]
		super(name, options)
		
		Thread.new {
			while true
				self.reachable = Ping.pingecho(self.ip_address)
				sleep 5
			end
		}
	end	
end

#126.184