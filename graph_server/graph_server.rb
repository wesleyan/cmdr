require 'rubygems'
require 'sinatra'
require 'tempfile'
require 'couchrest'

class String
	def us
		self.downcase.gsub(" ", "_")
	end
end

get '/' do
	db = CouchRest.database("http://localhost:5984/rooms")
	room = db.get(params[:room])
	sources = db.get("_design/wescontrol_web").view("sources", :key => params[:room])		
	devices = db.get("_design/room").view("devices_for_room", :key => params[:room])
	
	
graph = %Q\digraph F {
	nodesep=0.5;
	rankdir=LR;
	splines=true;
	rank=same;
	bgcolor="transparent";
	fontcolor="#FFFFFF";
	node [shape=record,width=0.1,height=0.1,color="#FFFFFF"];

	sources [label = "Sources|#{
		sources["rows"].collect{|source|
			name = source["value"]["name"]
			"<#{name.us}>#{name.capitalize}"
		}.join("|")
	}",height=2.5,fontcolor="#FFFFFF"];

	node [width = 1.5];
	
	#{
		devices["rows"].collect{|device|
			name = device["value"]["attributes"]["name"]
			if device["value"]["class"] == "ExtronVideoSwitcher"
				%Q&#{name.us} [label = "<top>#{name.capitalize}|<i1>Input 1|<i2>Input 2|<i3>Input 3|<i4>Input 4|<i5>Input 5|<i6>Input 6",fontcolor=white]&
			else
				%Q&#{name.us} [label = "<top>#{name.capitalize}",fontcolor=white]&
			end
		}.join("\n\t")
	}

	#{
		sources["rows"].collect{|source|
			name = source["value"]["name"]
			input = source["value"]["input"]
			if input["switcher"]
				"sources:#{name.us} -> extron:i#{input["switcher"]} [label = \"#{input["projector"]}\",fontcolor=white, color=white]"
			else
				"sources:#{name.us} -> projector [label = \"#{input["projector"]}\",fontcolor=white,color=white]"
			end
		}.join("\n\t")
	}
}
	\
	f = Tempfile.new("graph")
	f.write graph
	f.close
	f.path
	content_type 'image/svg+xml'
	svg = `dot -Tsvg #{f.path}`
end