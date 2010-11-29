require 'mq'
require 'fileutils'
require 'video-recorder'

module RoomtrolVideo
	class RemoteEncoder
		# Max number of encoding jobs to run simultaeneously
		MAX_THREADS = 1
		
		# ffmpeg command to encode a video
		ENCODING_COMMAND = "ffmpeg -i VIDEO_NAME.avi -acodec libfaac -ab 96k -vcodec libx264 -vpre slow -crf 22 -threads 0 VIDEO_NAME.mp4"
		
		def initialize
			@queue = []
			@db = CouchRest.database!(RemoteRecorder::VIDEO_DB)
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
		
		def watch
			case @state
			when PLAYING_STATE
				if !alive?(@current_pid)
					DaemonKit.logger.debug("Playing but not alive on #{@current_pid}")
					if @restart_count <= 0
						self.state = STOPPED_STATE
					else
						@restart_count = @restart_count.to_i - 1
						@current_pid = start_command PLAY_CMD
						send_fanout({
							:message => :recording_died,
							:restart_count => @restart_count
						})
					end
				else
					@restart_count = RESTART_LIMIT
				end
			when RECORDING_STATE
				if !alive?(@current_pid)
					if @restart_count <= 0
						self.state = STOPPED_STATE
					else
						@restart_count = @restart_count.to_i - 1
						file = filename_for_time(@recording_start_time)
						FileUtils.mkdir_p file[0]
						new_filename = "#{file.join("/")}.#{RESTART_LIMIT-@restart_count}"
						@current_pid = start_command RECORD_CMD.gsub("OUTPUT_FILE", new_filename)
						send_fanout({
							:message => :recording_died,
							:restart_count => @restart_count,
							:new_file => new_filename
						})
						@video_files << new_filename
					end
				else
					@restart_count = RESTART_LIMIT
				end
			else
				if !alive?(@current_pid)
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
				if @state == :recording
					@db.save_doc({
						"couchrest-type" => "Video",
						"created_at" => Time.now,
						"updated_at" => Time.now,
						"description" => nil,
						"encoded" => false,
						"files" => @video_files,
						"length" => Time.now - @recording_start_time,
						"recorded_at" => @recording_start_time
					})
				end
			end
			@state = new_state
		end
		#Thanks to God's process.rb for inspiration for the following methods
		def kill_command pid
			5.times{|time|
				begin
					Process.kill(2, pid)
				rescue Errno::ESRCH
					return
				end
				sleep 0.1
			}
		
			Process.kill('KILL', pid) rescue nil
		end
	
		def alive? pid
			#double exclamation mark returns true for a non-false values
			!!Process.kill(0, pid) rescue false
		end
	
		def start_command cmd
			r, w = IO.pipe
			begin
				outside_pid = fork do
					STDOUT.reopen(w)
					r.close
					pid = fork do
						#Process.setsid
						#Dir.chdir '/'
						$0 = cmd
						STDIN.reopen("/dev/null")
						STDOUT.reopen("/dev/null")
						STDERR.reopen(STDOUT)
						3.upto(256){|fd| IO.new(fd).close rescue nil}
						exec cmd
					end
					puts pid.to_s
				end
				Process.waitpid(outside_pid, 0)
				w.close
				pid = r.gets.chomp.to_i
				puts "Parent: #{pid}"
			ensure
				r.close rescue nil
				w.close rescue nil
			end
			puts "Starting command as #{child_pids(pid)[0]}"
			child_pids(pid)[0].to_i
		end
	
		def filename_for_time(time)
			dir = "/var/video/#{time.year}/#{time.month}/#{time.day}"
			file = "#{time.hour}.#{time.min}.#{time.sec}.avi"
			[dir, file]
		end
		def send_fanout hash
			@fanout.publish(hash.to_json)
		end
		def child_pids pid
			`ps -ef | grep #{pid}`.split("\n").collect{|line| line.split(/\s+/)}.reject{|parts| 
				parts[2] != pid.to_s || parts[-2] == "grep"
			}.collect{|parts| parts[1]}
		end
	end
end
