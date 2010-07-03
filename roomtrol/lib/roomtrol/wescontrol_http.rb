require 'rubygems'
require 'eventmachine'
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
			@queue = "roomtrol:http:#{self.object_id}"
			@deferred_responses = {}
			@amq = MQ.new
			@amq.queue(@queue).subscribe{|json|
				msg = JSON.parse(json)
				if @deferred_responses[msg["id"]]
					@deferred_responses[msg["id"]].succeed(msg["result"])
				end
			}
		end
		
		def process_http_request
			resp = EventMachine::DelegatedHttpResponse.new( self )
			resp.headers['content-type'] = "application/json"
			@path = @http_request_uri.split('/').collect{|a| a == "" ? nil : a}.compact
			
			if @path[0] == 'devices'
				devices resp
			#elsif @path[0] == 'watch' Watch won't work with messagequeue
			#	watch resp
			#elsif @path[0] == 'controller'
			#	controller resp
			else
				resp.status = 404
				resp.content = {"error" => "resource_not_found"}.to_json() + "\n"
				resp.send_response
			end
			# once download is complete, send it to client
			#http.callback do |r|
			#resp.status = 200
			#resp.content = r[:content]
			#resp.send_response
		end
		
		#TODO: Think about how to reimplement this with the new scheme
		#for now, it's disabled
		def watch resp
			@method_table ||= self.class.instance_variable_get(:@method_table)
			
			content = {}

			devices = []
			if !@path[1]
				resp.status = 200
				devices = @method_table.collect{|devices| devices[:device]}
			elsif @method_table[@path[1]]
				devices = [@method_table[@path[1]][:device]]
			else
				resp.status = 404
				content = {"error" => "device_not_found"}
				resp.content = content.to_json + "\n"
				resp.send_response
				return
			end
			
			devices.each{|device|
				device.register_for_changes.callback {|var, val|
					content = {var => val}
					resp.status = 200
					resp.content = content.to_json + "\n"
					resp.send_response
				}
			}
		end
		
		#def controller resp
		#	resp.status = 200
		#	resp.content = {
		#		"mac" 			=> MAC.addr,
		#		"id" 			=> @couchid,
		#		"attributes" 	=> @controller.attributes,
		#		"belongs_to"	=> @controller.belongs_to,
		#		"class"			=> @controller.class
		#	}.to_json + "\n"
		#	resp.send_response
		#end
		
		def devices resp
			@method_table ||= self.class.instance_variable_get(:@method_table)
			
			if !@path[1]
				resp.status = 200
				content = @method_table
				resp.content = content.to_json + "\n" 
				resp.send_response
			elsif !@path[2]
				resp.status = 400
				content = {:error => :must_provide_target}.to_json + "\n"
				resp.send_response
			elsif @method_table[@path[1]]
				case @http_request_method
				when "GET"
					get (@path, resp)
				when "POST"
					post @path, resp
				end
			else
				resp.status = 404
				content = {"error" => "device_not_found"}
				resp.content = content.to_json + "\n" 
				resp.send_response
			end
		end
		
		def defer_device_operation resp, device_req, device
			deferrable = EM::DefaultDeferrable.new
			deferrable.timeout = TIMEOUT
			
			deferrable.callback {|result|
				resp.status = result[:error] ? 500 : 200
				resp.content = result.delete(:id).to_json + "\n"
				resp.send_response
			}.errback {
				resp.status = 500
				resp.content = {:error => :timed_out}.to_json + "\n"
				resp.send_response
			}
			@deferred_responses[device_req[:id]] = deferrable
			amq.queue('roomtrol:dqueue:#{device}').publish(device_req.to_json)
		end
		
		#A get request looks like this: GET /devices/Extron/power
		#and returns something like this: {"result" => false}
		def get path, resp
			device_req = {
				:id => UUIDTools::UUID.random_create.to_s,
				:queue => @queue,
				:type => :state_get,
				:var => path[2]
			}
			defer_device_operation resp, device_req, path[1]
		end
	
		#A post request looks like this: POST /devices/Extron/power -d {'value' => true}
		#or like this: POST /devices/Extron/zoom -d {'args' => [2.0]}
		#and returns something like this: {"result" => true}
		def post path, resp
			begin
				data = JSON.parse(@http_post_content)
				device = @method_table[path[1]]
				device_req = {
					:id => UUIDTools::UUID.random_create.to_s,
					:queue => @queue
				}
				if data['value']
					device_req[:type] = :state_set
					device_req[:var] = path[2]
					device_req[:value] = data['value']
				else
					device_req[:type] = :command
					device_req[:method] = path[2]
					device_req[:args] = data['args']
				end
				defer_device_operation resp, device_req, path[1]
			rescue JSON::ParserError
				resp.status = 400
				content = {"error" => "bad_json"}
				resp.send_response
			end
		end
	
		def set_var device, var, value, resp
			content = nil
			if device[:methods][var.to_sym]
				if @@kind_verifier[device[:methods][var.to_sym][:kind].to_sym].call(value, device[:methods][var.to_sym])
					deal_with_device_feedback device[:device].send("set_#{var}", value), var, resp
				else
					content = {"error" => "#{var}_invalid_data"}
				end
			else
				content = {"error" => "#{var}_not_found"}
			end
			content
		end
	end
end
