require 'rubygems'
require 'eventmachine'
require 'em-http'
require 'json'
require 'uri'
require 'uuidtools'

module EventMachine
  module Protocols
    class CouchDB
      def self.connect connection_params
        puts "*****Connecting" if $debug
        self.new(connection_params)
      end
      def initialize(connection_params)
        @host = connection_params[:host] || '127.0.0.1'
        @port = connection_params[:port] || 80
        @timeout = connection_params[:timeout] || 10
      end
      def get_all_dbs(&callback)
        http = EventMachine::HttpRequest.new("http://#{@host}:#{@port}/_all_dbs/").get :timeout => @timeout 
        http.callback {
          callback.call(JSON.load(http.response))
        }
        http.errback {
          raise "CouchDB Exception. Unable to get all dbs. #{http.errors.join('\n')}"
        }
      end
      def create_db(db_name, &callback)
        http = EventMachine::HttpRequest.new("http://#{@host}:#{@port}/#{db_name}/").put 
        if block_given?
          http.callback {
            callback.call()
          }
        end
        http.errback {
          raise "CouchDB Exception. Unable to create db"
        }
      end
      def get_db(db_name, &callback)
        http = EventMachine::HttpRequest.new("http://#{@host}:#{@port}/#{db_name}/").get :timeout => @timeout
        http.callback {
          callback.call(JSON.load(http.response))
        }
        http.errback {
          raise "CouchDB Exception. Unable to get db"
        }
      end
      def delete_db(db_name, &callback)
        http = EventMachine::HttpRequest.new("http://#{@host}:#{@port}/#{db_name}/").delete 
        if block_given?
          http.callback {
            callback.call()
          }
        end
        http.errback {
          raise "CouchDB Exception. Unable to delete db"
        }
      end
      def get(database, id, &callback)
        http = EventMachine::HttpRequest.new("http://#{@host}:#{@port}/#{database}/#{id}").get :timeout => @timeout 
        http.callback {
          callback.call(JSON.load(http.response))
        }
        http.errback {
          raise "CouchDB Exception. Unable to get document"
        }
      end
      def save(database, doc, &callback)
        id = doc['_id']
        id ||= UUIDTools::UUID.random_create.to_s
        puts "Making request to: #{"http://#{@host}:#{@port}/#{database}/#{id}"}"
        http = EventMachine::HttpRequest.new("http://#{@host}:#{@port}/#{database}/#{id}").put :body => JSON.dump(doc)
        http.callback {
          callback.call(JSON.load(http.response))
        }
        http.errback {
          puts "Failed"
          raise "CouchDB Exception. Unable to save document"
        }
      end
      def update(database, old_doc, new_doc, &callback)
        id, rev = get_id_and_revision(old_doc)
        new_doc["_rev"] = rev
        new_doc["_id"] = id
        http = EventMachine::HttpRequest.new("http://#{@host}:#{@port}/#{database}/#{id}").put :body => JSON.dump(new_doc)
        http.callback {
          callback.call(JSON.load(http.response))
        }
        http.errback {
          raise "CouchDB Exception. Unable to save document"
        }
      end
      def delete(database, doc, &callback)
        doc_id, doc_revision = get_id_and_revision(doc)
        http = EventMachine::HttpRequest.new(URI.parse("http://#{@host}:#{@port}/#{database}/#{doc_id}?rev=#{doc_revision}")).delete
        http.callback{
          callback.call
        }
        http.errback {
          raise "CouchDB Exception. Unable to delete document"
        }
      end
      def get_id_and_revision(doc)
        if doc.has_key? "_id"
          return doc["_id"], doc["_rev"]
        else
          return doc["id"], doc["rev"]
        end
      end
    end
  end
end


