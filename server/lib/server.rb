require 'rubygems'
require 'sinatra'
require 'tempfile'
require 'couchrest'
require 'json'
require 'base64'
require 'net/ldap'
require "#{File.dirname(__FILE__)}/server/database"

LOCAL_DEVEL = true
COOKIE_EXPIRE = 24*60*60

class String
	def us
		self.downcase.gsub(" ", "_")
	end
end

post '/setup_db' do
	Database.setup_database
end

post '/auth/login' do
	puts "Doing login"
	json = JSON.parse(request.body.read.to_s)
	username = json["username"]
	password = json["password"]
	couch = CouchRest.database!("http://127.0.0.1:5984/roomtrol_server")
	authenticated = false

	if user = couch.view("auth/users", {:key => username})["rows"][0]
		if LOCAL_DEVEL
			authenticated = (password == "apassword")
		else
			ldap = Net::LDAP.new
			ldap.host = "gwaihir.wesad.wesleyan.edu"
			ldap.auth "#{username}@wesad.wesleyan.edu", password
			authenticated = username && password && username != "" && password != "" && ldap.bind
		end
	end
	if authenticated
		puts "Authenticated"
		#TODO: Figure out a more secure way of generating the token
		token = Digest::SHA1.hexdigest("#{Time.now + Time.now.usec + (rand * 1000-500)}")
		response.set_cookie "auth_token", {:value => token, :expires => Time.now+COOKIE_EXPIRE}
		user["value"]["auth_token"] = token
		user["value"]["auth_expire"] = (Time.now+COOKIE_EXPIRE).to_i
		couch.save_doc(user["value"])
		{"auth" => "success", "auth_token" => token}.to_json + "\n"
	else
		status 401
		{"auth" => "failed"}.to_json + "\n"
	end
end

post '/update_devices' do
	require "#{File.dirname(__FILE__)}/server/device.rb"
	require "#{File.dirname(__FILE__)}/server/device_lib/RS232Device"
	require "#{File.dirname(__FILE__)}/server/devices/Projector"
	require "#{File.dirname(__FILE__)}/server/devices/VideoSwitcher"
	require "#{File.dirname(__FILE__)}/server/devices/Computer"

	errors = []
	couch = CouchRest.database!("http://127.0.0.1:5984/drivers")
	Dir.glob("#{File.dirname(__FILE__)}/server/devices/*.rb").each{|device|
		begin
			require device
			device_string = File.open(device).read
			data = JSON.load device_string.split("\n").collect{|line| line[1..-1]}.join("") \
			                                   .match(/---(.*)?---/)[1]
			puts "#{device}:"
			#puts data.inspect
			if record = couch.view("drivers/by_name", {:key => data["name"]})["rows"][0]
				data["_id"] = record["value"]["_id"]
				data["_rev"] = record["value"]["_rev"]
			end
			data["driver"] = true
			data["config"] = Object.const_get(data["name"]).config_vars
			puts data.inspect
			couch.save_doc(data)
		rescue
			errors << "Failed to load #{device}: #{$!}"
		rescue LoadError
			errors << "Failed to load #{device}: syntax error"
		end
	}
	"<pre>\n" + errors.join("\n") + "\n</pre>\n"
end
	

#Expects json like this:
#{
#	'room': 'asdf23jlkj34nas',
#	'record': {couchdb record update goes here}
#}
post '/config' do
	json = JSON.parse(request.body.read.to_s)
	json["room"]
end

post '/graph' do
	puts "Doing graph"
	#db = CouchRest.database("http://localhost:5984/rooms")
	#room = db.get(params[:room])
	#sources = db.get("_design/wescontrol_web").view("sources", :key => params[:room])		
	#devices = db.get("_design/room").view("devices_for_room", :key => params[:room])
	json = session = JSON.parse(request.body.read.to_s)
	sources = json["sources"]
	devices = json["devices"]
	extron = nil
	projector = nil
	
graph = %Q\digraph F {
	nodesep=0.5;
	rankdir=LR;
	splines=true;
	rank=same;
	bgcolor="transparent";
	fontcolor="#FFFFFF";
	node [shape=record,width=0.1,height=0.1,color="#FFFFFF"];

	sources [label = "Sources|#{
		sources.collect{|source|
			name = source["name"]
			"<#{name.us}>#{name.capitalize}"
		}.join("|")
	}",height=2.5,fontcolor="#FFFFFF"];

	node [width = 1.5];
	
	#{
		devices.collect{|device|
			name = device["name"]
			projector = name if device["Driver"] == "NECProjector"
			if device["driver"] == "ExtronVideoSwitcher"
				extron = name
				%Q&#{name.us} [label = "<top>#{name.capitalize}|<i1>Input 1|<i2>Input 2|<i3>Input 3|<i4>Input 4|<i5>Input 5|<i6>Input 6",fontcolor=white]&
			else
				%Q&#{name.us} [label = "<top>#{name.capitalize}",fontcolor=white]&
			end
		}.join("\n\t")
	}

	#{
		sources.collect{|source|
			name = source["name"]
			input = source["input"]
			if input["switcher"]
				"sources:#{name.us} -> extron:i#{input["switcher"]} [label = \"#{input["projector"]}\",fontcolor=white, color=white]"
			else
				"sources:#{name.us} -> projector [label = \"#{input["projector"]}\",fontcolor=white,color=white]"
			end
		}.join("\n\t")
	}
	
	#{
		if projector && extron
			"#{extron} -> #{projector}"
		end
	}
}
	\
	f = Tempfile.new("graph")
	f.write graph
	f.close
	f.path
	content_type 'application/json'
	puts "Waiting for graph generation"
	#svg = `dot -Tsvg #{f.path}`
	#JSON.dump({:data => Base64.encode64(svg)})
	JSON.dump({:data => "hello"})
end