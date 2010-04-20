require 'drb/drb'
class VideoRecorder < Wescontrol::Device
	
	SERVER_URI = "drbunix:///tmp/god.17165.sock"
	
	state_var :recording, :kind => 'boolean'
	state_var :recording_started, :kind => 'time', :editable => false
	state_var :recording_stopped, :kind => 'time', :editable => false
	
	def initialize(options)
		Thread.abort_on_exception = true
		options = options.symbolize_keys
		puts "Initializing Video Recorder #{options[:name]} on #{options[:port]}"
		puts "starting god"
		puts `god`
		@_god = DRbObject.new_with_uri(SERVER_URI)
		super(options)
	end
		
	def set_recording(on)
		if on
			if !@_god.ping
				puts "Starting god"
				`god`
			end
			if !@_god.status || !@_god.status["recorder"]
				`god load #{File.dirname(__FILE__)}/../../bin/encoder_watch.god`
			end
			if @_god.status && @_god.status["recorder"][:state] == :unmonitored
				puts "Starting recorder"
				self.recording_started = Time.now
				`god start recorder`
			end
		else
			if @_god.status && @_god.status["recorder"][:state] != :unmonitored
				puts "Stopping recorder"
				self.recording_stopped = Time.now
				`god stop recorder`
			end
		end
		@_god && @_god.status ? @_god.status["recorder"][:state] != :unmonitored : nil
	end
end