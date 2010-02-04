module WesControl
	class WesControlRoom < WesControl
		def initialize
			begin
				@room = Room.find_by_mac(Mac.addr)
				throw "Room Does Not Exist" unless @room
			rescue
				raise "The room has not been added the database"
			end

			device_hashes = Room.devices(@room["id"])
			super(device_hashes)
		end
	end
	
	class Room
		@database = "http://localhost:5984/rooms"
		
		def self.find_by_mac(mac, db_uri = @database)
			db = CouchRest.database(db_uri)
			retried = false
			begin
				db.get("_design/room").view("by_mac", {:key => mac})['rows'][0]
			rescue RestClient::ResourceNotFound
				Room.define_db_views(db_uri)
				if !retried #prevents infinite retry loop
					retried = true
					retry
				end
				nil
			rescue
				nil
			end
		end
		
		def self.devices(room, db_uri = @database)
			db = CouchRest.database(db_uri)
			retried = false
			begin
				db.get("_design/room").view("devices_for_room", {:key => room})['rows']
			rescue RestClient::ResourceNotFound
				Room.define_db_views(db_uri)
				if !retried #prevents infinite retry loop
					retried = true
					retry
				end
				nil
			rescue
				nil
			end
		end
		
		def self.define_db_views(db_uri)
			db = CouchRest.database(db_uri)

			doc = {
				"_id" => "_design/room",
				:views => {
					:by_mac => {
						:map => "function(doc) {
							if(doc.attributes && doc.attributes[\"mac\"]){
								emit(doc.attributes[\"mac\"], doc);
							}
						}".gsub(/\s/, "")
					},
					:devices_for_room => {
						:map => "function(doc) {
							if(doc.belongs_to)
							{
								emit(doc.belongs_to, doc);
							}
						}".gsub(/\s/, "")
					}
				}
			}
			begin 
				doc["_rev"] = db.get("_design/room").rev
			rescue
			end
			db.save_doc(doc)
		end
	end
end
