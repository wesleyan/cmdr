require 'rubygems'
require 'sinatra'
require 'tempfile'
require 'couchrest'
require 'json'
require 'base64'

class String
	def us
		self.downcase.gsub(" ", "_")
	end
end

post '/graph' do
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
	svg = `dot -Tsvg #{f.path}`
	JSON.dump({:data => Base64.encode64(svg)})
end