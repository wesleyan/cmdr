#---
#{
#	"name": "Computer",
#	"depends_on": "Device",
#	"description": "A generic computer class, providing reachability monitoring",
#	"author": "Micah Wylde",
#	"email": "mwylde@wesleyan.edu",
#	"type": "Computer"
#}
#---

require 'wol'

require 'timeout'
require "socket"

module Ping
	def pingecho(host, timeout=5, service="echo")
		begin
			timeout(timeout) do
				s = TCPSocket.new(host, service)
				s.close
			end
		rescue Errno::ECONNREFUSED
			return true
		rescue Timeout::Error, StandardError
			return false
		end
		return true
	end
	module_function :pingecho
end


class Computer < Wescontrol::Device
	configure do
		ip_address :type => :string
		mac_address :type => :string
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
				self.reachable = Ping.pingecho(self.ip_address) rescue nil
				sleep 5
			end
		}
	end	
end

#126.184