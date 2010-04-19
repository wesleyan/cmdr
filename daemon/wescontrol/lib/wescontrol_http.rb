require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
require 'json'

module Wescontrol 
	class WescontrolHTTP < EventMachine::Connection
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
		
		def process_http_request
			resp = EventMachine::DelegatedHttpResponse.new( self )
			resp.headers['content-type'] = "application/json"
			@path = @http_request_uri.split('/').collect{|a| a == "" ? nil : a}.compact
			
			if @path[0] == 'devices'
				devices resp
			elsif @path[0] == 'watch'
				watch resp
			elsif @path[0] == 'controller'
				controller resp
			else
				resp.status = 404
				resp.content = {"error" => "resource_not_found"}
				resp.send_response
			end
			# once download is complete, send it to client
			#http.callback do |r|
			#resp.status = 200
			#resp.content = r[:content]
			#resp.send_response
		end
		
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
			
			content = {}
			
			operation = proc {
				if !@path[1]
					resp.status = 200
					content = @method_table
				elsif @method_table[@path[1]]
					case @http_request_method
					when "GET"
						content = get @path, resp
					when "POST"
						content = post @path, resp
					end
				else
					resp.status = 404
					content = {"error" => "device_not_found"}
				end
				#resp.send_response
			}
			callback = proc {|res|
				resp.content = content.to_json + "\n" if content
				begin		
					resp.send_response
				rescue
				end
			}
			
			EM.defer(operation, callback)
		end
		
		def get path, resp
			content = {}
			resp.status = 200
			state_vars = @method_table[path[1]][:device].to_couch['state_vars']
			if !path[2]
				content = state_vars
			elsif state_vars[path[2].to_sym]
				content = state_vars[path[2].to_sym]
			else
				resp.status = 404
				content = {"error" => "variable_not_found"}
			end
			content
		end
	
		def post path, resp
			content = {}
			begin
				updates = JSON.parse(@http_post_content)
				device = @method_table[path[1]]
				if !path[2]
					updates.each{|k,v|
						content.merge!(set_var(device, k, v))
					}
				elsif path[2].to_sym == :command
					content = send_command device, updates.keys[0], updates[updates.keys[0]], resp
				else
					content = set_var device, path[2].to_sym, updates, resp
				end
				resp.status = 200
			rescue JSON::ParserError
				resp.status = 400
				content = {"error" => "bad_json"}
			#rescue
			#	resp.status = 500
			#	content = {"error" => $!}
			end
			content
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
		
		def send_command device, command, value, resp
			deal_with_device_feedback device[:device].send(command, value), :result, resp
		end
		
		def deal_with_device_feedback feedback, name, resp
			if feedback.is_a? EM::Deferrable
				feedback.callback{|fb|
					resp.status = 200
					resp.content = {name => fb}.to_json + "\n"
					resp.send_response
				}
				feedback.errback{|error|
					resp.status = 400
					resp.content = {:error => error}.to_json + "\n"
					resp.send_response
				}
			else
				resp.status = 200
				resp.content = {name => feedback}.to_json + "\n"
				resp.send_response
				#sleep(0.1) #wait for value to update
				#content[var] = device[:device].send("#{var}")
			end
		end
	end
end
