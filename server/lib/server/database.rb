module Database
	def self.setup_database
		rooms = CouchRest.database!("http://127.0.0.1:5984/rooms")
		doc = {
			"_id" => "_design/wescontrol_web",
			:language => "javascript", 
			:views => {
				:building => {
					:map => "function(doc) {
						if(doc.class && doc.class == \"Building\" && doc.attributes && doc.attributes[\"name\"])
						{
							emit([doc._id, 0], {
								name: doc.attributes[\"name\"],
								guid: doc._id, rooms:[]});
							}
							if(doc.class && doc.class == \"Room\" && doc.belongs_to){
								var room = {
									guid: doc._id,
									_rev: doc._rev,
									building: doc.belongs_to,
									devices: []
								};
								for(var attr in doc.attributes){
									room[attr] = doc.attributes[attr];
								}
								emit([doc.belongs_to, 1], room);
							}
							if(doc.device && doc.belongs_to){
								//the [0] in the key makes sure all of the devices are sorted after the other docs
								var device = {
									guid: doc._id,
									_rev: doc._rev,
									name: doc.attributes.name,
									room: doc.belongs_to,
									state_vars: doc.attributes.state_vars,
									driver: doc.class,
									config: doc.attributes.config
								};
							emit([[0], 2], device);
						}
					}"
				}, 
				"sources" => {
					"map" => "function(doc) {
						if(doc.source && doc.belongs_to)emit(doc.belongs_to, doc);
					}"
				},
				"actions" => {
					"map"=>"function(doc) {
						if(doc.action && doc.belongs_to)emit(doc.belongs_to, doc);
					}"
				}
			}
		}
		begin 
			doc["_rev"] = rooms.get("_design/wescontrol_web").rev
		rescue
		end
		rooms.save_doc(doc)

		roomtrol_server = CouchRest.database!("http://127.0.0.1:5984/roomtrol_server")
		doc = {
			"_id" => "_design/auth",
			:language => "javascript",
			:views => {
				:users => {
					:map => "function(doc){ if(doc.is_user)emit(doc.username, doc); }"
				},
				:tokens => {
					:map => "function(doc) { if(doc.is_user)emit(doc.auth_token, doc); }"
				}
			}
		}
		begin 
			doc["_rev"] = roomtrol_server.get("_design/auth").rev
		rescue
		end
		roomtrol_server.save_doc(doc)
		drivers = CouchRest.database!("http://127.0.0.1:5984/drivers")
		doc = {
			"_id" => "_design/drivers",
			:language => "javascript",
			:views => {
				:by_name => {
					:map => "function(doc) { if(doc.driver)emit(doc.name, doc); }"
				}
			}
		}
		begin 
			doc["_rev"] = drivers.get("_design/drivers").rev
		rescue
		end
		drivers.save_doc(doc).to_json + "\n"
		
	end
end