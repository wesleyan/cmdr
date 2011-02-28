require "rubygems"
require "eventmachine"
require "../lib/em-couchdb"

# Need to write test for updating doc...
# But before that write example test framework :)
# Also need to implement get all docs in db

describe "Working with Databases" do
  it "return databases available in couchdb" do
    EventMachine.run do
      couch = EventMachine::Protocols::CouchDB.connect :host => 'localhost', :port => 5984
      couch.create_db("test-project")
      couch.get_all_dbs {|dbs| dbs.should include "test-project"}
      couch.get_db("test-project") do |db|
        db["db_name"].should == "test-project" 
        couch.delete_db(db["db_name"]) do
          EventMachine.stop
        end
      end
    end
  end
end

describe "Working with documents" do
  it "should get the saved document" do
    EventMachine.run do
      couch = EventMachine::Protocols::CouchDB.connect :host => 'localhost', :port => 5984
      couch.create_db("test-project")
      couch.get_db("test-project") do |db|
        couch.save(db["db_name"], {:name => "couchdb", "description" => "awesome"}) do |doc| 
          couch.get(db["db_name"], doc["id"]) do |doc|
            doc["name"].should == "couchdb"
            doc["description"].should == "awesome"
            couch.delete(db["db_name"], doc) do
              couch.delete_db(db["db_name"]){
                EventMachine.stop
              }
            end
          end
        end
      end
    end
  end
end
