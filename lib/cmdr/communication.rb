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

require 'eventmachine'
require 'net/http'
require 'cmdr/constants'

module Cmdr
  def Cmdr.send_event event
        event['device'] ||= "N/A"
        event['device_type'] ||= "N/A"
        event['location'] ||= "N/A"
        event['severity'] ||= "N/A"
        event['title'] ||= "N/A"
        event['description'] ||= "N/A"
        event['time'] ||= Time.now.to_i
        EM.defer do
          begin
            DaemonKit.logger.info("Received error: #{event}")
            url = URI.parse ERROR_URI
            headers = {"Content-Type" => "application/json",
                       "Accept-Encoding" => "gzip,deflate",
                       "Accept" => "application/json"}
            http = Net::HTTP.new(url.host, url.port)
            response = http.post(url.path, event.to_json, headers)
            DaemonKit.logger.info "Sent event. Response: #{response.body}"
          rescue
          end
        end
  end
end
