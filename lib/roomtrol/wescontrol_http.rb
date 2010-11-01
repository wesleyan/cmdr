require 'rubygems'
require 'evma_httpserver'
require 'json'
require 'amqp'
require 'uuidtools'

module Wescontrol 
	class WescontrolHTTP < EventMachine::Connection
		TIMEOUT = 2.0
		include EventMachine::HttpServer
		
		@@kind_verifier = {
			:boolean => 	proc {|a, options| a.is_a?(TrueClass) || a.is_a?(FalseClass)},
			:number => 		proc {|a, options| a.is_a? Numeric},
			:string => 		proc {|a, options| a.is_a? String},
			:percentage => 	proc {|a, options| (a*100).round >= 0 && (a*100).round <= 100},
			:decimal =>		proc {|a, options| a.is_a? Numeric},
			:option => 		proc {|a, options| options[:options].include? a},
			:array =>		proc {|a, options| a.is_a? Array},
			#TODO: Actually implement support for setting times
			:time =>		proc {|a, options| begin; Time.at(a); rescue; nil; end}
		}
		
		def initialize
			@amq = MQ.new
			@queue_name = "roomtrol:http:#{self.object_id}"
			@queue = @amq.queue(@queue_name)
			@deferred_responses = {}
			@queue.subscribe{|json|
				msg = JSON.parse(json)
				DaemonKit.logger.debug("Received HTTP response: #{msg}")
				if @deferred_responses[msg["id"]]
					@deferred_responses.delete(msg["id"]).succeed(msg)
				end
			}
		end
		
		def unbind
			@queue.unsubscribe
	    end
		
		def process_http_request
			resp = EventMachine::DelegatedHttpResponse.new( self )
			resp.headers['content-type'] = "application/json"
			@path = @http_request_uri.split('/').collect{|a| a == "" ? nil : a}.compact
			
			if @path[0] == 'devices'
				devices resp
			else
				resp.status = 404
				resp.content = {"error" => "resource_not_found"}.to_json() + "\n"
				resp.send_response
			end
		end
				
		def devices resp
			DaemonKit.logger.debug("Running devices")
			@devices ||= self.class.instance_variable_get(:@devices)
			
			if !@path[1]
				resp.status = 200
				resp.content = {:devices => @devices}.to_json + "\n" 
				resp.send_response
			elsif !@path[2]
				resp.status = 400
				resp.content = {:error => :must_provide_target}.to_json + "\n"
				resp.send_response
			elsif @devices.include? @path[1]
				case @http_request_method
				when "GET"
					get @path, resp
				when "POST"
					post @path, resp
				end
			else
				resp.status = 404
				resp.content = {:error => :device_not_found}.to_json + "\n" 
				resp.send_response
			end
		end
		
		def defer_device_operation resp, device_req, device
			deferrable = EM::DefaultDeferrable.new
			deferrable.timeout TIMEOUT
			
			deferrable.callback {|result|
				DaemonKit.logger.debug("Callback called with #{result}")
				resp.status = result[:error] ? 500 : 200
				result.delete("id")
				resp.content = result.to_json + "\n"
				resp.send_response
			}
			deferrable.errback {|error|
				resp.status = 500
				resp.content = {:error => :timed_out}.to_json + "\n"
				resp.send_response
				@deferred_responses.delete(deferrable)
			}
			@deferred_responses[device_req[:id]] = deferrable
			DaemonKit.logger.debug("Sending #{device}: #{device_req}")
			@amq.queue("roomtrol:dqueue:#{device}").publish(device_req.to_json)
		end
		
		#A get request looks like this: GET /devices/Extron/power
		#and returns something like this: `{"result" => false}`
		def get path, resp
			DaemonKit.logger.debug("Running get on #{path}")
			device_req = {
				:id => UUIDTools::UUID.random_create.to_s,
				:queue => @queue_name,
				:type => :state_get,
				:var => path[2]
			}
			defer_device_operation resp, device_req, path[1]
		end
	
		#A post request looks like this: `POST /devices/Extron/power -d {'value' => true}`
		#or like this: `POST /devices/Extron/zoom -d {'args' => [2.0]}`
		#and returns something like this: `{"result" => true}`
		def post path, resp
			begin
				data = JSON.parse(@http_post_content)
				DaemonKit.logger.debug("Received POST: #{data}")
				device_req = {
					:id => UUIDTools::UUID.random_create.to_s,
					:queue => @queue_name
				}
				if data['value'] != nil #we want to allow false values, but not nil values
					device_req[:type] = :state_set
					device_req[:var] = path[2]
					device_req[:value] = data['value']
				else
					device_req[:type] = :command
					device_req[:method] = path[2]
					device_req[:args] = data['args'] if data['args']
				end
				defer_device_operation resp, device_req, path[1]
			rescue JSON::ParserError, TypeError
				resp.status = 400
				content = {"error" => "bad_json"}
				resp.send_response
			end
		end
	end
end
