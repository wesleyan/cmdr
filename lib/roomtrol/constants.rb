module Wescontrol
	# The AMQP topic on which to send events
	EVENT_TOPIC = "roomtrol:events"
  DB_URI = "htt://localhost:5984"

  PUB_PATH = "ipc:///tmp/roomtrol-pub-port"
  SUB_PATH = "ipc:///tmp/roomtrol-sub-port"

  DEVICE_REP_PATH = "ipc:///tmp/roomtrol-rep-port"
  DEVICE_REQ_PATH = "ipc:///tmp/roomtrol-req-port"
end
