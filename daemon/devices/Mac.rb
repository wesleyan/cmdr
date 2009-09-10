class Mac < Computer
	
	def current_app
		path = `osascript -e "set front_app to (path to frontmost application as Unicode text)"`
		return path.split(":")[-1]
	end
	
	def current_user
		return `who`.split("   ")[0]
	end
	
	def uptime
		t = `uptime`[/up.*?,.*?,/]
		days = t[/up \d* days/][/\d+/].to_i
		hours, minutes = [/\d{1,2}:\d\d/].split(":").collect{|a| a.to_i}
		return minutes + (hours + (days * 24)) * 60 #returns number of minutes of uptime
	end
end
