require 'mq'
require 'fileutils'
require 'tempfile'
require_relative 'process'
require_relative 'video-recorder'

module RoomtrolVideo
	class EncodingProcessMonitor < ProcessMonitor
		# ffmpeg command to encode a video
		ENCODING_COMMAND = "ffmpeg -i INPUT -acodec libfaac -ab 96k -vcodec libx264 -vpre slow -crf 22 -threads 0 OUTPUT"
		
		attr_accessor :input_video
		attr_accessor :output_video
		
		def initialize(input, output)
			@input_video = input
			@output_video = output
			super(ENCODING_COMMAND.gsub("INPUT", input).gsub("OUTPUT", output))
		end
		
		def video_valid?
			!!FFMPEG::InputFormat.new(@output_video) rescue false
		end
	end
	class RemoteEncoder
		# Max number of encoding jobs to run simultaeneously
		MAX_THREADS = 1
			
		def initialize
			@queue = []
			@db = CouchRest.database!(RemoteRecorder::VIDEO_DB)
			@processes = {}
		end
					
		# Starts the recording server. Until this is called, the recorder will not respond
		# to messages.
		def run
			AMQP.start(:host => '127.0.0.1') do
				MQ.new.queue('listener').bind(mq.fanout(RemoteRecorder::FANOUT_EXCHANGE)).subscribe do |json|
					# check if the message is a recording finished message
					message = JSON.parse(json)
					if message[:message] == "recording_finished"
						# add the encoding job to the queue
						@queue.unshift({
							:id => message[:doc_id],
							:files => message[:files]
						})
						
					end
				end
			end
		end
		
		private
		
		def process_queue
			check_processes
			if @processes.size < MAX_THREADS && !@queue.empty?
				start_encoding_job(@queue.pop)
			end	
		end
		
		def start_encoding_job job
			record = @db.get(job[:id])
			path = job[:files].size == 1 ? job[:files][0] : combine_files(job[:files])
			process = EncodingProcessMonitor.new(path, job[:files][0].gsub(".avi", ".mp4"))
			@processes[job[:id]] = process
			process.start
		end
		
		# raw AVI can be combined by concatentation
		def combine_files files
			tempfile = Tempfile.new("video")
			path = tempfile.path
			tempfile.close
			`cat #{files.join(" ")} > #{path}.avi`
			path
		end
	
		def watch
			@processes.each{|id, process|
				unless process.alive?
					if process.video_valid?
						doc = @db.get(id)
						doc["file"] = process.output_video
						doc["encoded"] = true
				end
			}
		end
		
		def get_frame file
			video = FFMPEG::InputFormat.new(file)
			# we choose a frame from 1/3 through, because that seems like a resonable heuristic
			# this can probably be tuned to a better value later
			video.first_video_stream.seek(video.duration/3)
			frame = video.first_video_stream.decode_frame.to_ppm
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
				if @state == :recording
					doc = @db.save_doc({
						"couchrest-type" => "Video",
						"created_at" => Time.now,
						"updated_at" => Time.now,
						"description" => nil,
						"encoded" => false,
						"files" => @video_files,
						"length" => Time.now - @recording_start_time,
						"recorded_at" => @recording_start_time
					})
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
