# Your starting point for daemon specific classes. This directory is
# already included in your load path, so no need to specify it.
require 'eventmachine'
require 'em-proxy'
require 'couchrest'

module RoomtrolServer
	class ProxyServer			
		HTTP_MATCHER = /(GET|POST|PUT|DELETE|HEAD) (.+?)(?= HTTP)/
		COOKIE_MATCHER = /auth_token\w*?=\w*?"?(.+)"?/
		
		def initialize
			@couch = CouchRest.database!("http://127.0.0.1:5984/roomtrol_server")
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
				begin
					conn.server :couch, :host => "127.0.0.1", :port => 5984
					conn.server :roomtrol, :host => "127.0.0.1", :port => 4567
					#conn.server :http, :host => "127.0.0.1", :port => 81

					conn.on_data do |data|
						begin
							action, path = data.match(HTTP_MATCHER)[1..2]
							result = case path.split("/")[1]
							when "rooms"
								authenticate data, :couch, conn
							when "device"
								authenticate data, :roomtrol, conn
							when "auth"
								puts "Doing auth"
								[data, [:roomtrol]]
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
				rescue
					conn.send_data "HTTP/1.1 500 Unknown error occurred\r\n"
					conn.unbind
				end
			}
		end
	end
end