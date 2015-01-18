# Copyright (C) 2014 Wesleyan University
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'couchrest'
require 'cmdr/authenticate'

module Cmdr
  class CmdrRoom < Cmdr
    def initialize
      @controller = Room.get_all_rooms()
      device_hashes = Room.devices()
      super(device_hashes)
    end
  end
  
  class Room
    @credentials = Authenticate.get_credentials
    @database = "http://#{@credentials["user"]}:#{@credentials["password"]}@localhost:5984/rooms"

    def self.get_all_rooms(db_uri = @database)
      db = CouchRest.database!(db_uri)
      db.get("_design/room").view("all_rooms")['rows']
    end
    
    def self.devices(db_uri = @database)
      db = CouchRest.database!(db_uri) 
      db.get("_design/room").view("devices_for_room")['rows']
    end
  end
end
