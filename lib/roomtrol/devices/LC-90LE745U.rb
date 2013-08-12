#---
#{
# "name": "LC-90E745U", 
# "depends_on": "SocketTv", 
# "description": "Controls Sharp LC-90E745U TV.", 
# "author": "Justin Raymond", 
# "email": "jraymond@wesleyan.edu" 
#} 
#--- 

class LC90E745U < SocketTv 

  INPUT_HASH = {"TV" => "ITVD0","HDMI 1" => "IAVD1","HDMI 2" => "IAVD2",
    "HDMI 3" => "IAVD3","HDMI 4" => "IAVD4","COMPONENT" => "IAVD5",
    "VIDEO 1" => "IAVD6","VIDEO 2" => "IAVD7","PC" => "IAVD8"} 

  AV_MODE_HASH = {"STANDARD" => 100,"MOVIE" => 200,"GAME" => 300,"USER" => 400,
    "DYNAMIC(Fixed)" => 500, "DYNAMIC" => 600,"PC" => 700,"STANDARD(3D)" => 140,
    "MOVIE(3D)" => 150,"GAME(3D)" => 160,"AUTO" => 100} 

  POS_HASH = {"H-POSITION" => "HPOS","V-POSITION" => "VPOS","CLOCK" => "CLCK",
    "PHASE" => "PHSE"}

  VIEW_HASH = {"Side Bar[AV]" => 1,"S.Stretch[AV]" => 2,"Zoom[AV]" => 3,
    "Stretch[AV]" => 4,"Normal[PC]" => 5,"Zoom[PC]" => 6,"Stretch[PC]" => 7,
    "Dot by Dot[PC][AV]" => 8,"Full Screen[AV]" => 9,"Auto" => 10,
    "Original" => 11}

  SURROUND_HASH = {"Normal" => 1,"Off" => 2,"3D Hall" => 4,
    "3D Movie" => 5,"3D Standard" => 6,"3D Stadium" => 7}

  SLEEP_HASH = {"Off" => 0,"30min" => 1,"60min" => 2,"90min" => 3,"120min" => 4}

  THREE_D_HASH = {"Off" => 0,"2D->3D" => 1,"SBS" => 2,"TAB" => 3,
    "3D->2D(SBS)" => 4,"3D->2D(TAB)" => 5,"3D auto" => 6,"2D auto" => 7}

  configure do
    DaemonKit.logger.info "@Initializing LC90E745 at URI #{options[:uri]} with name #{@name}"
  end

  managed_state_var :power,
    :type => :boolean,
    :display_order => 1,
    :action => proc{|on|
      send_string "RSPW#{on ? "2" : "0"}\r"
    }
  managed_state_var :standby,
    :type => :boolean,
    :action => proc{|on|
      send_string "POWR#{on ? "1" : "0"}\r"
    }

  managed_state_var :input,
    :type => :option,
    :options => ['TV','HDMI 1','HDMI 2','HDMI 3','HDMI 4','COMPONENT',
                'VIDEO 1','VIDEO 2','PC'],
    :display_order => 2,
    :action => proc{|source|
      send_string "#{INPUT_HASH[source]}\r"
    }

  managed_state_var :av_mode,
    :type => :option,
    :options => ['STANDARD','MOVIE','GAME','USER','DYNAMIC(Fixed)','DYNAMIC',
      'PC','STANDARD(3D)','MOVIE(3D)','GAME(3D)','AUTO'],
    :display_order => 4,
    :action => proc{|av_mode|
      send_string "AVMD#{AV_MODE_HASH[av_mode]}0\r"
    }

  managed_state_var :volume,
    :type => :number,
    :display_order => 3,
    :action => proc{|vol|
      send_string "VOLM#{vol}00\r"
    }

  managed_state_var :position,
    :type => :option,
    :display_order => 5,
    :options => ['H-POSITION','V-POSITION','CLOCK','PHASE']
    :action => proc{|pos|
      send_string "#{POS_HASH[pos]}0000"
    }

  managed_state_var :view_mode,
    :type => :option,
    :options => ['Side Bar[AV]','S.Stretch[AV]','Zoom[AV]','Stretch[AV]',
      'Normal[PC]','Zoom[PC]','Stretch[PC]','Dot by Dot[PC][AV]',
      'Full Screen[AV]','Auto','Original']
    :action => proc{|mode|
      send_string "WIDE#{VIEW_HASH[mode]}00\r"
    }

  managed_state_var :mute,
    :type => :boolean,
    :action => proc{|on|
      send_string "MUTE#{on ? 1 : 2}\r"
    }

  managed_state_var :surround,
    :type => :option,
    :options => ['Normal','Off','3D Hall','3D Movie','3D Standard',
      '3D Stadium']
    :action => proc{|mode|
      send_string "ACSU#{SURROUND_HASH[mode]}\r"
    }

  managed_state_var :sleep_timer,
    :type => :option,
    :options => ['Off','30min','60min','90min','120min'],
    :action => proc{|time|
      send_string "OFTM#{SLEEP_HASH[time]}\r"
    }

  managed_state_var :channel_analog,
    :type => :number,
    :action => proc{|chnl|
      send_string "DCCH#{chnl}\r"
    }

  managed_state_var :threeD,
    :type => :option,
    :options => ['Off','2D->3D','SBS','TAB','3D-2D(SBS)','3D-2D(TAB)',
      '3D auto','2D auto']
    :action => proc{|mode|
      send_string "TDCH#{THREE_D_HASH[mode]}\r"
    }



