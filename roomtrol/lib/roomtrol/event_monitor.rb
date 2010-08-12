require 'mq'
require 'couchrest'
module Wescontrol
	class EventMonitor
		def self.run
			buffer = {}
			AMQP.start(:host => '127.0.0.1'){
				db = CouchRest.database("http://localhost:5984/rooms")
				amq = MQ.new
				amq.queue(EVENT_QUEUE).subscribe{|msg|
					msg[:event] = true
					db.save_doc(msg)
				}
			}
		end
	end
end