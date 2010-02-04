class Mac < Computer

	config_var :username
	config_var :password
	
	def initialize(options)
		options = options.symbolize_keys

		Thread.abort_on_exception = true
	
		super(:ip_address => options[:ip_address])
		
		tasks = {
			:current_app => ['osascript -e "set front_app to (path to frontmost application as Unicode text)"', proc{|response|
				self.current_app = response.split(":")[-1]
			}],
			:current_user => ['who', proc{|response| 
				self.current_user = response.split("   ")[0]
			}],
			:uptime => ["uptime", proc{|response|
				t = response[/up.*?,.*?,/]
				days = t[/up \d* days/][/\d+/].to_i
				hours, minutes = [/\d{1,2}:\d\d/].split(":").collect{|a| a.to_i}
				self.uptime = minutes + (hours + (days * 24)) * 60 #returns number of minutes of uptime
			},
			
		}
	end
end
