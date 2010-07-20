# Your starting point for daemon specific classes. This directory is
# already included in your load path, so no need to specify it.
require 'eventmachine'
require 'em-proxy'
require 'couchrest'
require 'net/ssh'

module RoomtrolServer
	class ProxyServer			
		HTTP_MATCHER = /(GET|POST|PUT|DELETE|HEAD) (.+?)(?= HTTP)/
		COOKIE_MATCHER = /auth_token\w*?=\w*?"?(.+)"?/
		
		def initialize
			@couch = CouchRest.database!("http://127.0.0.1:5984/roomtrol_server")
			@couch_forwards = {
				"c180fad1e1599512ea68f1748eb601ea" => 5984
			}
		end
		def port_forward
			Net::SSH.start("host", "user", :password => "password") do |ssh|
				ssh.forward.remote(80, "www.google.com", 1234)
				ssh.loop { true }
			end
		end
		def authenticate data, server, conn
			begin
				matched = data.split("Cookie:")[1].match(COOKIE_MATCHER)
				auth_token = matched[1] if matched
				user = @couch.view("auth/tokens", {:key => auth_token.strip})["rows"][0]["value"]
				if user["auth_expire"] > Time.now.to_i
					return [data, [server]]
				end
			rescue
			end
			conn.send_data "HTTP/1.1 401 User is not authorized\r\n"
			conn.unbind
			nil
		end
		def run
			Proxy.start(:host => "0.0.0.0", :port => 2352, :debug => true){|conn|
				#begin
					conn.server :couch, :host => "127.0.0.1", :port => 5984
					conn.server :roomtrol, :host => "127.0.0.1", :port => 4567
					#conn.server :http, :host => "127.0.0.1", :port => 81
					conn.server :cc180fad1e1599512ea68f1748eb601ea, :host => "127.0.0.1", :port => 5984

					conn.on_data do |data|
						begin
							action, path = data.match(HTTP_MATCHER)[1..2]
							result = case path.split("/")[1]
							when "rooms"
								authenticate data, :couch, conn
							when "device"
								authenticate data, :roomtrol, conn
							when "config"
								#/config/uuid_of_room/rooms/xxx
								if authenticate data, nil, conn
									room = path.split("/")[2]
									server = "c#{room}".to_sym
									DaemonKit.logger.debug("Room: #{room}")
									DaemonKit.logger.debug("Server: #{server}")
									new_path = "/" + path.split("/")[3..-1].join("/")
									DaemonKit.logger.debug("NewPath: #{new_path}")
									[data.gsub(path, new_path), [server]]
								end
							when "auth"
								puts "Doing auth"
								[data, [:roomtrol]]
							when "graph"
								puts "Graph"
								authenticate data, :roomtrol, conn
							else
								[data, [:http]]
							end
							result
						rescue
							DaemonKit.logger.error("Error: #{$!}")
						end
					end

					conn.on_response do |server, resp|
						resp
					end

					conn.on_finish do |name|
					end
				#rescue
				#	DaemonKit.logger.error("Unknown error: #{$!}")
				#	conn.send_data "HTTP/1.1 500 Unknown error occurred\r\n"
				#	conn.unbind
				#end
			}
		end
	end
end