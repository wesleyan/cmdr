#---
#{
# "name": "Computer",
# "depends_on": "Device",
# "description": "A generic computer class, providing reachability monitoring",
# "author": "Micah Wylde",
# "email": "mwylde@wesleyan.edu",
# "type": "Computer"
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


class Computer < Cmdr::Device
  configure do
    ip_address :type => :string
    mac_address :type => :string
  end
  #attempt to turn on the computer via WoL
  command :start, :action => proc{
    w = Wol::WakeOnLan.new(:address => configuration[:ip_address], :mac => self.mac_address)
    w.wake
  }
  
  #current info
  state_var :reachable, :type => :boolean, :editable => false, :display_order => 1
  
  def initialize(name, options)
    @ip_address = options[:ip_address]
    super(name, options)
    
    EM.defer {
      Thread.abort_on_exception = true
      while true
        self.reachable = Ping.pingecho(configuration[:ip_address])
        sleep 5
      end
    }
  end 
end

#126.184
