#---
#{
#	"name": "PJLinkProjector",
#	"depends_on": "SocketProjector",
#	"description": "Controls any projector capable of understanding the PJLink protocol standard, ie. the Epson PowerLite Pro G5750WU",
#	"author": "Jonathan Lyons",
#	"email": "jclyons@wesleyan.edu"
#}
#---
require 'digest/md5'

class PJLinkProjector < SocketProjector  
  INPUT_HASH = {"HDMI" => 32, "YPBR" => 13, "RGB1" => 11, "VIDEO" => 23, "SVIDEO" => 22}

  configure do
    DaemonKit.logger.info "@Initializing PJLinkProjector at URI #{options[:uri]} with name #{name}"
  end

  def initialize(name, options)
    options = options.symbolize_keys
    @_password = options[:password]
    super(name, options)
  end

  # Generates the auth key for pjlink
  #def receive_data data
  def read data
    EM.cancel_timer @_cooling_timer if @_cooling_timer
    @_cooling_timer = nil
    if data.start_with? "PJLINK 1"
      @_digest = Digest::MD5.hexdigest "#{data.chop[9..-1]}#{@_password}"
    elsif data == "%1POWR=1"
      # stop timer
    end
    super data 
  end

  def send_string(string)
    if string == "%1POWR 1"
      # Start timer
    end
    string = @_digest+string if @_digest
    super string
  end

	managed_state_var :power, 
		:type => :boolean,
		:display_order => 1,
		:action => proc{|on|
      "%1POWR #{on ? "1" : "0"}\r"
		}
	
	managed_state_var :input, 
		:type => :option,
		# Numbers correspond to HDMI, YPBR, RGB, RGB2, VID, and SVID in that order
		:options => [ 'HDMI', 'YPBR', 'RGB1', 'VID', 'SVID'],
		:display_order => 2,
		:action => proc{|source|
			"%1INPT #{INPUT_HASH[source]}\r"
		}

	managed_state_var :mute, 
		:type => :boolean,
		:action => proc{|on|
			"%1AVMT #{on ? "31" : "30"}\r"
		}
	
	managed_state_var :video_mute,
		:type => :boolean,
		:display_order => 4,
		:action => proc{|on|
			"%1AVMT #{on ? "31" : "30"}\r"
		}
		
  #managed_state_var :operational,
  #  :type => :boolean,
  #  :action => proc{

	responses do
		#ack ":"
		error :general_error, "ERR", "Received an error"
		match :power,  /%1POWR=(.+)/, proc{|m|
	 		DaemonKit.logger.info "Received power value #{m[1]}"
			  self.power = (m[1] == "1")
	  		self.cooling = (m[1] == "2")
	  		self.warming = ((m[1] == "3") || (m[1] == "ERR3"))	
		}
		#match :mute,       /%1AVMT=(.+)/, proc{|m| self.mute = (m[1] == "31")}
		match :video_mute, /%1AVMT=(.+)/, proc{|m| self.video_mute = (m[1] == "31")}
		match :input,      /%1INPT=(.+)/, proc{|m| self.input = m[1]}
		
	end
	
	requests do
           send :power, "#{@_digest}%1POWR ?\r", 1
           send :source, "#{@_digest}%1INPT ?\r", 1
           send :mute, "#{@_digest}%1AVMT ?\r", 1
           #send :lamp_usage, "*ltim=?#", 0.1
           send :lamp_usage, "#{@_digest}%1LAMP ?\r", 0.1
	end

end
