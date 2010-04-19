require 'drb/drb'
class VideoRecorder < Wescontrol::Device
	
	SERVER_URI = "drbunix:///tmp/god.17165.sock"
	
	state_var :recording, :kind => 'boolean'
	state_var :recording_started, :kind => 'time', :editable => false
	state_var :recording_stopped, :kind => 'time', :editable => false
	virtual_var :recording_time, :kind => 'number', :depends_on => [:recording_started, :recording_stopped], :transformation => proc {
		if this.recording
			Time.now - this.recording_started
		else
			this.recording_stopped - this.recording_started
		end
	}, :display_order => 6
	
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
				this.recording_started = Time.now
				`god start recorder`
			end
		else
			if @_god.status && @_god.status["recorder"][:state] != :unmonitored
				this.recording_stopped = Time.now
				`god stop recorder`
			end
		end
	end
end