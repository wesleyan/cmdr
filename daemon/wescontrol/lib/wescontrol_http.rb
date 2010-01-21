require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
require 'json'

module Wescontrol 
	class WescontrolHTTP < EventMachine::Connection
		include EventMachine::HttpServer
		
		@@kind_verifier = {
			:boolean => proc {|a, options| a.is_a? TrueClass || a.is_a?(FalseClass)},
			:number => proc {|a, options| a.is_a? Numeric},
			:string => proc {|a, options| a.is_a? String},
			:percentage => proc {|a, options| a.is_a?(Float) && a >= 0 && a <= 1},
			:option => proc {|a, options| options[:options].include? a}
		}
		
		def process_http_request
			resp = EventMachine::DelegatedHttpResponse.new( self )
			resp.headers['content-type'] = "application/json"
			
			@method_table ||= self.class.instance_variable_get(:@method_table)
			
			path = @http_request_uri.split('/').collect{|a| a == "" ? nil : a}.compact
			content = {}
			
			operation = proc{
				if path[0] == 'devices'
					if !path[1]
						resp.status = 200
						content = @method_table
					elsif @method_table[path[1]]
						case @http_request_method
						when "GET"
							content = get path, resp
						when "POST"
							content = post path, resp
						end
					else
						resp.status = 404
						content = {"error" => "device_not_found"}
					end
					#resp.send_response
				else
					resp.status = 404
					content = {"error" => "resource_not_found"}
					#resp.send_response
				end
			}
			callback = proc {|res|
				resp.content = content.to_json + "\n"
				resp.send_response
				puts "Finished processing: #{path.inspect}"
			}
			
			EM.defer(operation, callback)
			
			# once download is complete, send it to client
			#http.callback do |r|
			#resp.status = 200
			#resp.content = r[:content]
			#resp.send_response
		end
		
		def get path, resp
			content = {}
			resp.status = 200
			state_vars = @method_table[path[1]][:device].to_couch['state_vars']
			if !path[2]
				content = state_vars
			#elsif state_vars[path[2].to_sym]
			#	content = state_vars[path[2].to_sym]
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
						content.merge!(set_var device, k, v)
					}
				else
					content = set_var device, path[2].to_sym, updates
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
	
		def set_var device, var, value
			content = {}
			if device[:methods][var.to_sym]
				if @@kind_verifier[device[:methods][var.to_sym][:kind].to_sym].call(value, device[:methods][var.to_sym])
					device[:device].send("set_#{var}", value)
					content[var] = device[:device].send("#{var}")
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