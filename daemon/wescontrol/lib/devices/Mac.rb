require 'chronic'
class Mac < Computer

	config_var :username
	config_var :password
	
	def initialize(options)
		options = options.symbolize_keys

		Thread.abort_on_exception = true
	
		super(:ip_address => options[:ip_address])
		
		tasks = {
			:current_user => ['who', proc{|response|
				users = response.split("\n").collect{|x| x.split(/   */).collect{|y| y.strip}}.reject{|x| x[1] != "console"}
				self.current_user = users[0][0]
				self.logged_in = users.size > 0
				self.logged_in_time = Time.now - Chronic.parse(users[0][2], :context => :past)
				#self.idle_time = 
			}],
			:current_app => ['osascript -e "set front_app to (path to frontmost application as Unicode text)"', proc{|response|
				self.current_app = response.split(":")[-1]
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