#---
#{
#	"name": "VideoRecorder",
#	"depends_on": "Device",
#	"description": "Controls the video recording service",
#	"author": "Micah Wylde",
#	"email": "mwylde@wesleyan.edu",
#	"type": "Video Recorder"
#}
#---

require 'uuidtools'

class VideoRecorder < Wescontrol::Device
	SEND_QUEUE = "roomtrol:video:send:queue"
	FANOUT_QUEUE = "roomtrolvideo:messages"
	state_var :state, :type => :option, :options => [:playing, :recording, :stopped]
	state_var :recording_started, :type => :time, :editable => false
	state_var :recording_stopped, :type => :time, :editable => false
	state_var :restarts_remaining,:type => :integer, :editable => false
	
	def initialize(name, options)
		Thread.abort_on_exception = true
		options = options.symbolize_keys
		DaemonKit.logger.info "Initializing Video Recorder #{name}"
		@response_queue = "roomtrol:#{name}:video_resp"
		@requests = {}
		
		super(name, options)
	end
	
	def amqp_setup
		mq = MQ.new
		mq.queue(@response_queue).subscribe do |json|
			msg = JSON.load(json)
			if deferrable = @requests.delete(msg["id"])
				deferrable.set_deferred_status(msg["result"] == true ? :succeeded : :failed)
			else
				DaemonKit.logger.debug("Unhandled message: #{msg}")
			end
		end
	
		mq.queue(FANOUT_QUEUE).subscribe do |json|
			msg = JSON.load(json)
			DaemonKit.logger.debug("Received on fanout: #{msg}")
			case msg["message"]
			when "state_changed"
				self.state = msg["to"].to_sym
				time = DateTime.parse(msg["time"])
				case msg["to"]
				when "recording"
					self.recording_started = time
				when "stopped"
					self.recording_stopped = time
				end
			when "playback_died"
				self.restarts_remaining = msg["restarts_left"]
			when "recording_died"
				self.restarts_remaining = msg["restarts_left"]
			end
		end
	end
		
	def set_state(state)
		req = {
			:id => UUIDTools::UUID.random_create.to_s,
			:queue => @response_queue
		}
		case state.to_s
		when "playing" then req[:command] = "start_playing"
		when "recording" then req[:command] = "start_recording"
		when "stopped" then req[:command] = "stop"
		else
			DaemonKit.logger.error("unknown state: #{state}")
			return
		end
		deferrable = EM::DefaultDeferrable.new
		@requests[req[:id]] = deferrable
		mq = MQ.new
		mq.queue(SEND_QUEUE).publish(req.to_json)
		deferrable
	end
end