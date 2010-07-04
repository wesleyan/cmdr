require 'drb/drb'
class VideoRecorder < Wescontrol::Device
	
	SERVER_URI = "drbunix:///tmp/god.17165.sock"
	
	state_var :recording,         :type => :boolean
	state_var :recording_started, :type => :time, :editable => false
	state_var :recording_stopped, :type => :time, :editable => false
	
	def initialize(name, options)
		Thread.abort_on_exception = true
		options = options.symbolize_keys
		DaemonKit.logger.info "Initializing Video Recorder #{options[:name]} on #{options[:port]}"
		DaemonKit.logger.info "starting god:"
		super(name, options)
	end
	
	def run
		DaemonKit.logger.info `god`
		@_god = DRbObject.new_with_uri(SERVER_URI)
		super
	end
		
	def set_recording(on)
		if on
			if !@_god.ping
				DaemonKit.logger.debug puts "Starting god"
				`god`
			end
			if !@_god.status || !@_god.status["recorder"]
				`god load #{File.dirname(__FILE__)}/../../bin/encoder_watch.god`
			end
			if @_god.status && @_god.status["recorder"][:state] == :unmonitored
				DaemonKit.logger.debug "Starting recorder"
				self.recording_started = Time.now
				`god start recorder`
			end
		else
			if @_god.status && @_god.status["recorder"][:state] != :unmonitored
				DaemonKit.logger.debug "Stopping recorder"
				self.recording_stopped = Time.now
				`god stop recorder`
			end
		end
		@_god && @_god.status ? @_god.status["recorder"][:state] != :unmonitored : nil
	end
end