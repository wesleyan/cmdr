# Ideally probe should be handed an active serial port and be able to decide whether the device connected to the serial port is an NECProjector, an EpsonProjector, an extron, or something else
# it will then symlink /dev/projector, /dev/projector2, /dev/extron etc. to the serial port, depending on what the device is, and auto-configure the device to be used with Roomtrol
# RoomtrolProbe can be hooked into system-wide udev events through udev rules, and notified every time, for instance, a device is plugged and unplugged from the system, at which point
# RoomtrolProbe will probe the device and configure it and add it to the Touchscreen sources

require 'RS232Device.rb'
require 'devices/NECProjector.rb'
require 'devices/EpsonProjector.rb'

    
module RoomtrolProbe  
    def run
     
      necprojector = NECProjector.new
      NECProjector.
      
		end
end