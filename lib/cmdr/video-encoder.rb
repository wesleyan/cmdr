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

require 'mq'
require 'fileutils'
require 'tempfile'

module CmdrVideo
	class EncodingProcessMonitor < ProcessMonitor
		# ffmpeg command to encode a video
		ENCODING_COMMAND = "ffmpeg -i INPUT -acodec libfaac -ab 96k -vcodec libx264 -vpre slow -crf 22 -threads 3 OUTPUT 2>&1"
		# maximum number of times to retry encoding before giving up
		MAX_RESTARTS = 4
		
		attr_accessor :input_video
		attr_accessor :output_video
		
		def initialize(input, output)
			@input_video = input
			@output_video = output
			super(ENCODING_COMMAND.gsub("INPUT", input).gsub("OUTPUT", output))
		end
		
		def video_valid?
			output = `ffmpeg -i #{@output_video} 2>&1`
			(/Duration: N\/A/im).match(output).nil?
		end
		
		def video_duration
			return nil unless video_valid?
		    
			output = `ffmpeg -i #{@output_video} 2>&1`
			raw_duration = /Duration:\s*([0-9\:\.]+),/.match(output)[1]
			units = raw_duration.split(":")
			(units[0].to_i * 60 * 60 * 1000) + (units[1].to_i * 60 * 1000) + (units[2].to_f * 1000).to_i
		end
	end
	class RemoteEncoder
		# Max number of encoding jobs to run simultaeneously
		MAX_THREADS = 1
		# ffmpeg command to grab a video frame
		FRAME_GRAB_COMMAND = "ffmpeg -itsoffset TIME_OFFSET -i INPUT -y -vcodec mjpeg -vframes 1 -an -f rawvideo OUTPUT 2>&1"

		def initialize
			@queue = []
			@db = CouchRest.database!(RemoteRecorder::VIDEO_DB)
			@processes = {}

      doc = {
        "_id" => "_design/video_encoder",
        "views" => {
          "unencoded" => {
            "map" => "function(doc) {
              if(doc['couchrest-type'] === 'Video' && doc.encoded === false){
                emit(doc.recorded_at, doc);
              }
            }"
          }
        }
      }
      begin
        doc["_rev"] = @db.get("_design/video_encoder").rev
      rescue
      end
      @db.save_doc(doc)
		end
					
		# Starts the encoding server
		def run
			AMQP.start(:host => '127.0.0.1') do
				MQ.new.queue('encoder_listener').bind(MQ.new.fanout(RemoteRecorder::FANOUT_EXCHANGE)).subscribe do |json|
					# check if the message is a recording finished message
					DaemonKit.logger.debug("Got message: #{json}")
					message = JSON.parse(json)
					if message["message"] == "recording_finished"
						DaemonKit.logger.debug("Got recording finish message: #{message}")
						# add the encoding job to the queue
						@queue.unshift({
							:id => message["doc_id"],
							:files => message["files"]
						})
						process_queue
					end
				end
				EM.add_periodic_timer(1.0) do
					watch
					process_queue
				end
        # periodically check whether we for some reason missed a video
        # which is sitting unencoded somewhere
        EM.add_periodic_timer(15) do
          @db.get("_design/video_encoder").view("unencoded")['rows'].each{|v|
            unless @queue.collect{|x| x[:id]}.include? v["value"]["_id"]
              @queue.unshift({
                               :id => v["value"]["_id"],
                               :files => v["value"]["files"]
                             })
            end
          }
        end
			end
		end
		
		private
		
		def process_queue
			if @processes.size < MAX_THREADS && !@queue.empty?
				start_encoding_job(@queue.pop)
			end	
		end
		
		def start_encoding_job job
			DaemonKit.logger.debug("Starting encoding job: #{job}")
			record = @db.get(job[:id])
			path = job[:files].size == 1 ? job[:files][0] : combine_files(job[:files])
			process = EncodingProcessMonitor.new(path, job[:files][0].gsub(".avi", ".mp4"))
			@processes[job[:id]] = process
			process.start
			DaemonKit.logger.debug("Encoding job started: #{process.pid}")
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
			@processes.delete_if{|id, process|
				DaemonKit.logger.debug("Proccess: #{process.pid} alive? #{process.alive?}")
				if !process.alive?
					DaemonKit.logger.debug("Process no longer alive")
					if process.video_valid?
						DaemonKit.logger.debug("Encoding finished successfully")
						doc = @db.get(id)
						doc["file"] = process.output_video
						doc["encoded"] = true
						@db.save_doc(doc)
						frame_file = get_frame(process.output_video, process.video_duration)
						@db.put_attachment(doc, "video_still.jpg", File.read(frame_file))
            doc['files'].each do |f|
              File.delete(f)
            end
						next true
					else
						if process.restarts < MAX_RESTARTS
							process.start
						else
							doc = @db.get(id)
							doc["error"] = "failed_to_encode"
						end
					end
				end
				false
			}
		end
		
		def get_frame file, length
			tempfile = Tempfile.new("frame")
			path = tempfile.path + ".jpg"
			tempfile.close
			
			# we choose a frame from 1/3 through, because that seems like a resonable heuristic
			# this can probably be tuned to a better value later
			`#{FRAME_GRAB_COMMAND.gsub('INPUT', file).gsub('OUTPUT', path).gsub('TIME_OFFSET', (length/3).to_s)}`
			path
		end
	end
end
