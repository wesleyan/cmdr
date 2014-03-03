require 'mq'
require 'fileutils'

module CmdrVideo
	# This class is reponsible for recording video and playing back the
	# current state of the camera. It is controlled over AMQP. There are
	# several kinds of messages you can send over the wire, all of which
	# should be encoded via JSON. In each of these messages, id is a
	# unique id which the client can use to recognize a response (as
	# each response will also include this id) and queue is the queue to
	# which the client wants the response sent.
	# 
	# ###start_time_get
	# To get the time that recording started at, send a message like this:
	#
	# 	!!!json
	# 	{
	# 		id: "FF00F317-108C-41BD-90CB-388F4419B9A1",
	# 		queue: "cmdr:video_recorder:35",
	# 		get: "start_time"
	# 	}
	# You will get a response like this:
	# 	!!!json
	# 	{
	# 		id: "FF00F317-108C-41BD-90CB-388F4419B9A1",
	# 		result: "2010-10-19 17:45:29 -0400"
	# 	}
	#
	# ###current_state_get
	# To get the current state (one of RemoteRecorder::PlayingState, 
	# RemoteRecorder::RECORDING_STATE or RemoteRecorder::STOPPED_STATE):
	# 
	# 	!!!json
	# 	{
	# 		id: "D62F993B-E036-417C-948B-FEA389480984",
	# 		queue: "cmdr:video_recorder:35",
	# 		get: "current_state"
	# 	}
	# You will get a response like this:
	# 	!!!json
	# 	{
	# 		id: "D62F993B-E036-417C-948B-FEA389480984",
	# 		result: "playing"
	# 	}
	# ###start_recording
	#
	# 	!!!json
	# 	{
	# 		id: "D62F993B-E036-417C-948B-FEA389480984",
	# 		queue: "cmdr:video_recorder:35",
	# 		command: "start_recording"
	# 	}
	# You will get a response like this:
	# 	!!!json
	# 	{
	# 		id: "D62F993B-E036-417C-948B-FEA389480984",
	# 		result: true #on success, false on failure
	# 		start_time: "2010-10-19 17:45:29 -0400"
	# 	}
	#
	# ###start_playing
	#
	# 	!!!json
	# 	{
	# 		id: "D62F993B-E036-417C-948B-FEA389480984",
	# 		queue: "cmdr:video_recorder:35",
	# 		command: "start_playing"
	# 	}
	# You will get a response like this:
	# 	!!!json
	# 	{
	# 		id: "D62F993B-E036-417C-948B-FEA389480984",
	# 		result: true #on success, false on failure
	# 	}
	# ###stop
	#
	# 	!!!json
	# 	{
	# 		id: "D62F993B-E036-417C-948B-FEA389480984",
	# 		queue: "cmdr:video_recorder:35",
	# 		command: "stop" #stops current command
	# 	}
	# You will get a response like this:
	# 	!!!json
	# 	{
	# 		id: "D62F993B-E036-417C-948B-FEA389480984",
	# 		result: true, #on success, false on failure
	# 		stop_time: "20-10-19 17:50:29 -0400"
	# 	}
	#
	#
	# If you register yourself on the message fanout exchange (at
	# RemoteRecorder::FANOUT_EXCHANGE), you will receive messages when
	# interesting things happen. Below are the messages you might
	# receive:
	#
	# 	!!!json
	# 	{
	# 		message: "state_changed",
	# 		from: "playing",
	# 		to: "stopped"
	# 	}
	#
	# 	{
	#		message: "playback_died",
	# 		restarts_left: 4
	# 	}
	#
	# 	{
	# 		message: "recording_died",
	# 		restarts_left: 3
	# 		new_file: "/var/video/2010/10/20/04.10.50.avi.7"
	# 	}
	class RemoteRecorder
		# The command to start recording video
		RECORD_CMD = %q?
		gst-launch v4l2src ! 'video/x-raw-yuv,width=720,height=480,framerate=30000/1001' ! \
		    tee name=t_vid ! deinterlace ! queue ! cairotextoverlay text="recording" valign=bottom halign=right ! \
		    xvimagesink sync=true t_vid. ! queue ! \
		    videorate ! 'video/x-raw-yuv,framerate=30000/1001' ! deinterlace ! queue ! mux. \
		    osssrc device=/dev/dsp6 ! audio/x-raw-int,rate=48000,channels=2,depth=16 ! queue ! \
		    audioconvert ! queue ! mux. avimux name=mux ! \
		    filesink location=OUTPUT_FILE?

		# The command to start video playback, but not record
		PLAY_CMD =  %q?
    gst-launch v4l2src ! 'video/x-raw-yuv,width=720,height=480,framerate=30000/1001' ! \
        deinterlace ! queue ! \
        xvimagesink sync=true . ?
		
		# The database where video information is stored
		VIDEO_DB = "http://localhost:5984/videos"
		
		# Currently playing video back
		PLAYING_STATE = :playing
		# Currently recording video
		RECORDING_STATE = :recording
		# Currently stopped
		STOPPED_STATE = :stopped
		# The queue on which the recorder sends fanout messages to interested parties
		FANOUT_EXCHANGE = "cmdr:video:messages"
		# The number of times to try restarting a recording that has stopped
		RESTART_LIMIT = 10
		# The number of times per second to checkup on processess
		WATCH_FREQUENCY = 4	
	
		attr_accessor :recording_start_time, :state
	
		# Creates a new RemoteRecorder instance
		# @param [String] response_queue The name of the queue over which messages should
		# 	be sent from the recorder to the client. The client should watch this queue.
		# @param [String] send_queue The name of the queue over which the client would like
		# 	to send messages to the recorder. It will watch this queue.
		def initialize send_queue
			@state = STOPPED_STATE
			@send_queue = send_queue
		end
		
		# Starts the recording server. Until this is called, the recorder will not respond
		# to messages.
		def run
			AMQP.start(:host => '127.0.0.1') do
				mq = MQ.new
				@fanout = MQ.new.fanout(FANOUT_EXCHANGE)
				@db = CouchRest.database!(VIDEO_DB)
				mq.queue(@send_queue).subscribe do |msg|
					DaemonKit.logger.debug("Received: #{msg}")
					req = JSON.parse(msg)
					resp = {:id => req["id"]}
					if req['get']
						case req['get']
						when "start_time"
							resp[:result] = @recording_start_time
						when "current_state"
							resp[:result] = @state
						else
							resp[:error] = "Invalid request"
						end
					elsif req['command']
						case req['command']
						when "start_playing"
							resp[:result] = !!start_playback
						when "start_recording"
							resp[:result] = !!start_recording
							resp[:start_time] = @recording_start_time
						when "stop"
							resp[:result] == !!stop
						else
							resp[:error] = "Invalid command"
						end
          elsif req['course']
            @course = req['course']
            DaemonKit.logger.debug("Setting course to #{@course}")
            resp[:result] = true
					else
						resp[:error] = "Invalid message"
					end
					mq.queue(req["queue"]).publish(resp.to_json)
				end
				EM.add_periodic_timer(1.0/WATCH_FREQUENCY) do
					watch
				end
			end
		end
	
		def start_playback
			@current_process.kill if @current_process
			
			self.state = PLAYING_STATE
      begin
        @current_process = ProcessMonitor.new(PLAY_CMD, true)
        @current_process.start
      rescue
        DaemonKit.logger.debug("Failed to start: $!")
      end
		end
	
		def start_recording
			@current_process.kill if @current_process
			
			@recording_start_time = Time.now
			self.state = RECORDING_STATE
			file = filename_for_time(@recording_start_time)
			FileUtils.mkdir_p file[0]
			
			@current_process = ProcessMonitor.new(RECORD_CMD.gsub("OUTPUT_FILE", file.join("/")), true)
			@current_process.start
			
			@video_files = [file.join("/")]
		end
	
		def stop
			if @current_process
				self.state = STOPPED_STATE
				@current_process.kill
			end
		end
	
		def watch
			case @state
			when PLAYING_STATE
				if @current_process && !@current_process.alive?
					DaemonKit.logger.debug("Playing but not alive on #{@current_process.pid}")
					if @current_process.restarts >= RESTART_LIMIT
						@current_process = nil
						self.state = STOPPED_STATE
					else
						@current_process.start
						send_fanout({
							:message => :recording_died,
							:restart_count => @current_process.restarts
						})
					end
				end
			when RECORDING_STATE
				if @current_process && !@current_process.alive?
					if @current_process.restarts >= RESTART_LIMIT
						@current_process = nil
						self.state = STOPPED_STATE
					else
						file = filename_for_time(@recording_start_time)
						FileUtils.mkdir_p file[0]
						new_filename = "#{file.join("/")}.#{@current_process.restarts}"
						@current_process.cmd = RECORD_CMD.gsub("OUTPUT_FILE", new_filename)
						@current_process.start
						send_fanout({
							:message => :recording_died,
							:restart_count => @current_process.restarts,
							:new_file => new_filename
						})
						@video_files << new_filename
					end
				end
			else
				if !@current_process || !@current_process.alive?
					self.state = STOPPED_STATE
				end
			end
		end
	
		private
		def state= new_state
			if @state != new_state
				send_fanout({
					:message => :state_changed,
					:from => @state,
					:to => new_state,
					:time => new_state == RECORDING_STATE ? @recording_start_time : Time.now
				})
				
				# if we're transitioning from recording to another state, we need to save a
				# record of the video to the database so that it can be shown in the web interface
				# and encoded by the encoding daemon
				if @state == RECORDING_STATE
					doc = @db.save_doc({
						"couchrest-type" => "Video",
						"created_at" => Time.now,
						"updated_at" => Time.now,
						"description" => nil,
						"encoded" => false,
						"files" => @video_files,
						"length" => Time.now - @recording_start_time,
            "recorded_at" => @recording_start_time,
            "course_id" => @course
					})
					DaemonKit.logger.debug("Sending message on fanout")
					send_fanout({
						:message => :recording_finished,
						:doc_id => doc["id"],
						:files => @video_files
					})
				end
			end
			@state = new_state
		end
	
		def filename_for_time(time)
			dir = "/var/video/#{time.year}/#{time.month}/#{time.day}"
			file = "#{time.hour}.#{time.min}.#{time.sec}.avi"
			[dir, file]
		end
		def send_fanout hash
			@fanout.publish(hash.to_json)
		end
	end
end
