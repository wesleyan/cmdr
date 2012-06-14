require 'yaml'
require 'openssl'

module Wescontrol
	class WescontrolRoom < Wescontrol
		def initialize
			retried = false
			begin
				@controller = Room.find_by_mac(MAC.addr)
				throw "Room Does Not Exist" unless @controller
			rescue
				unless retried
					Room.create_room
					retried = true
					retry
				end
				raise "The room could not be added to the database. Is CouchDB running?"
			end

			device_hashes = Room.devices(@controller["id"])
			@couchid = @controller['id']
			super(device_hashes)
		end
	end
	
	class Room
		@database = "http://roomtrol:Pr351d3nt@localhost:5984/rooms"

		def self.find_by_mac(mac, db_uri = @database)
      #credentials = Room.get_credentials
			#db = CouchRest.database!("#{credentials}@#{db_uri}")
      db = CouchRest.database!(db_uri)
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
      #credentials = Room.get_credentials
			#db = CouchRest.database!("#{credentials}@#{db_uri}")
      db = CouchRest.database!(db_uri) 
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
      #credentials = Room.get_credentials
			#db = CouchRest.database!("#{credentials}@#{db_uri}")
      db = CouchRest.database!(db_uri)

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
							if(doc.belongs_to && doc.device)
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
		
		def self.create_room(db_uri = @database)
			puts "Creating room"
      #credentials = Room.get_credentials
			#db = CouchRest.database!("#{credentials}@#{db_uri}")
      db = CouchRest.database!(db_uri)
			
			number = 0
			serial_ports = `ls /dev/serial/by-path`.split("\n").collect do |port|
				{
					"name" => "port#{number+=1}",
					"value" => "/dev/serial/by-path/#{port}"
				}
			end
			
			unless `ls /dev | grep lircd` == ""
				serial_ports << {"name" => "IR Port", "value" => "/dev/lircd"}
			end
			
			building_id = "cc7e9b6fe3e2757deba97d8d83157515"
			
			room_doc = {
				#:id => JSON.parse(RestClient.get("#{db.server.uri}/_uuids"))["uuids"][0],
				:class => "Room",
				:belongs_to => building_id,
				:attributes => {
					:name => "Unnamed room",
					:mac => MAC.addr,
					:ports => serial_ports
				}
			}
			
			building_doc = {
				'_id' => building_id,
				:class => "Building",
				:attributes => {
					:name => "Uncategorized"
				}
			}
			
			db.save_doc(room_doc)
			db.save_doc(building_doc)
		end

    #def self.get_credentials
    #  credentials = YAML::load_file "/var/roomtrol-daemon/credentials.yml"
    #  key = YAML::load_file "/var/roomtrol-daemon/key.yml"

    #  decipher = OpenSSL::Cipher::AES.new(128, :CBC)
    #  decipher.decrypt
    #  decipher.key = key["key"]
    #  decipher.iv = key["iv"]

    #  pw = decipher.update(credentials["password"]) + decipher.final
    #  auth = "#{credentials["user"]}:#{pw}"
    #end
	end
end
