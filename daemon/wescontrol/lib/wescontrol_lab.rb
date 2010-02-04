module WesControl
	class WesControlLab < WesControl
		def initialize
			begin
				controller = Controller.find_by_mac(Mac.addr)
				throw "Controller Does Not Exist" unless controller
			rescue
				raise "The controller has not been added the database"
			end

			device_hashes = Controller.devices(controller["id"])
			super(device_hashes)
		end
	end
	
	class Controller
		@database = "http://localhost:5984/rooms"
		
		def self.find_by_mac(mac, db_uri = @database)
			db = CouchRest.database(db_uri)
			retried = false
			begin
				db.get("_design/controller").view("by_mac", {:key => mac})['rows'][0]
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
		
		def self.devices(controller, db_uri = @database)
			db = CouchRest.database(db_uri)
			retried = false
			begin
				db.get("_design/controller").view("devices_for_controller", {:key => controller})['rows']
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
				"_id" => "_design/wescontrol",
				:views => {
					:by_mac => {
						:map => "function(doc) {
							if(doc.attributes && doc.attributes[\"controller_mac\"]){
								emit(doc.attributes[\"controller_mac\"], doc);
							}
						}".gsub(/\s/, "")
					},
					:devices_for_controller => {
						:map => "function(doc) {
							if(doc.controller)
							{
								emit(doc.controller, doc);
							}
						}".gsub(/\s/, "")
					}
				}
			}
			begin 
				doc["_rev"] = db.get("_design/controller").rev
			rescue
			end
			db.save_doc(doc)
		end
	end
end
