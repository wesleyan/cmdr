require '/usr/local/wescontrol/daemon/devices/PowerPoint.rb'
require 'net/ssh'

class PowerPointMac < PowerPoint
	def initialize(name, bus, config)
		@ip = config['ip']
		@username = config['username']
		@password = config['password']
	end
	
	def launch_program
		Net::SSH.start(@ip, @username, :password => @password) do |ssh|
			output = ssh.exec!('open /Applications/Microsoft\ Office\ 2008/Microsoft\ PowerPoint.app')
			puts output
		end
	end
	
		#[:open_ppt, 			["file:s"], 	["response:s"]],
		#[:launch_program, 		[], 			["response:s"]],
		#[:start_show, 			[], 			["response:s"]],
		#[:end_show,				[],				["response:s"]],
		#[:get_slides_as_png, 	[], 			[""]],
		#[:go_to_slide, 			["input:u"],	["response:s"]],
		#[:next_slide,			[],				["response:s"]],
		#[:previous_slide, 		[], 			["response:s"]],
		#[:current_slide, 		[], 			["number:u"]],
		#[:current_notes, 		[], 			["true:b"]]
		
end
