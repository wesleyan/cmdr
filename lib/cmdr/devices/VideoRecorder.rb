# Copyright (C) 2014 Wesleyan University
#
# This file is part of cmdr-devices.
#
# cmdr-devices is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# cmdr-devices is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with cmdr-devices. If not, see <http://www.gnu.org/licenses/>.

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

class VideoRecorder < Cmdr::Device
	SEND_QUEUE = "cmdr:video:send:queue"
	FANOUT_QUEUE = "cmdr:video:messages"
	state_var :state, :type => :option, :options => [:playing, :recording, :stopped]
  state_var :course, :type => :string
	state_var :recording_started, :type => :time, :editable => false
	state_var :recording_stopped, :type => :time, :editable => false
	state_var :restarts_remaining,:type => :integer, :editable => false

	
	def initialize(name, options)
		Thread.abort_on_exception = true
		options = options.symbolize_keys
		DaemonKit.logger.info "Initializing Video Recorder #{name}"
		@response_queue = "cmdr:#{name}:video_resp"
		@requests = {}
		
		super(name, options)
	end
	
	def run
		mq = MQ.new
		mq.queue(@response_queue).subscribe do |json|
			msg = JSON.load(json)
			if deferrable = @requests.delete(msg["id"])
				deferrable.set_deferred_status(msg["result"] == true ? :succeeded : :failed)
			elsif msg["id"] == "initial_state_get"
				self.state = msg["result"].to_sym
			else
				DaemonKit.logger.debug("Unhandled message: #{msg}")
			end
		end
		mq.queue('listener').bind(mq.fanout(FANOUT_QUEUE)).subscribe do |json|
			msg = JSON.load(json)
			DaemonKit.logger.debug("Received on fanout: #{msg}")
			case msg["message"]
			when "state_changed"
				self.state = msg["to"].to_sym
				time = DateTime.parse(msg["time"]).to_time
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
		
		mq.queue(SEND_QUEUE).publish(
			{
				:id => "initial_state_get",
				:queue => @response_queue,
				:get => "current_state"
			}.to_json
		)
		
		super
	end
		
	def set_state state
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

    send_req req
	end

  def set_course course
    DaemonKit.logger.debug("Setting course to #{course}")
    req = {
      :id => UUIDTools::UUID.random_create.to_s,
      :queue => @response_queue,
      :course => course
    }

    df = send_req req
    df.callback do
      self.course = course
    end
    df
  end

  def send_req req
    deferrable = EM::DefaultDeferrable.new
		@requests[req[:id]] = deferrable
		mq = MQ.new
		mq.queue(SEND_QUEUE).publish(req.to_json)
		deferrable
  end
end
