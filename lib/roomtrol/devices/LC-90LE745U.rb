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

  AV_MODE_HASH = {"STANDARD" => "1  ","MOVIE" => "2  ","GAME" => "3  ","USER" => "4  ",
    "DYNAMIC(Fixed)" => "5  ", "DYNAMIC" => "6  ","PC" => "7  ","STANDARD(3D)" => "14 ",
    "MOVIE(3D)" => "15 ","GAME(3D)" => "16 ","AUTO" => "100"} 

  POS_HASH = {"H-POSITION" => "HPOS","V-POSITION" => "VPOS","CLOCK" => "CLCK",
    "PHASE" => "PHSE"}

  VIEW_HASH = {"Side Bar[AV]" => "1 ","S.Stretch[AV]" => "2 ","Zoom[AV]" => "3 ",
    "Stretch[AV]" => "4 ","Normal[PC]" => "5 ","Zoom[PC]" => "6 ","Stretch[PC]" => "7 ",
    "Dot by Dot[PC][AV]" => "8 ","Full Screen[AV]" => "9 ","Auto" => "10",
    "Original" => "11"}

  SURROUND_HASH = {"Normal" => "1","Off" => "2","3D Hall" => "4",
    "3D Movie" => "5","3D Standard" => "6","3D Stadium" => "7"}

  SLEEP_HASH = {"Off" => "0","30min" => "1","60min" => "2","90min" => "3","120min" => "4"}

  THREE_D_HASH = {"Off" => "0","2D->3D" => "1","SBS" => "2","TAB" => "3",
    "3D->2D(SBS)" => "4","3D->2D(TAB)" => "5","3D auto" => "6","2D auto" => "7"}

  configure do
    DaemonKit.logger.info "@Initializing LC90E745 at URI #{options[:uri]} with name #{@name}"
  end

  #More information about the commands may be found on page 68 of the manual.
  #If 0, the power on command rejected. If on, the power on command accepter. 
  # When the power is in standby mode, commands also go to waiting status and
  # so power consumption is just about the same as usual. With the commands in
  # waiting status, the Center Icon Illumination on the front of the TV lights up.
  managed_state_var :power_on_cmd,
    :type => :boolean,
    :action => proc{|on|
      send_string "RSPW#{on ? "2" : "0"}   \r"
    }

  #If off tv goes to standby.
  managed_state_var :power,
    :type => :boolean,
    :display_order => 1,
    :action => proc{|on|
      send_string "POWR#{on ? "1" : "0"}   \r"
    }

  managed_state_var :input,
    :type => :option,
    :display_order => 2,
    :options => ['TV','HDMI 1','HDMI 2','HDMI 3','HDMI 4','COMPONENT','VIDEO 1','VIDEO 2','PC'],
    :action => proc{|source|
      send_string "#{INPUT_HASH[source]}   \r"
    }

  managed_state_var :av_mode,
    :type => :option,
    :options => ['STANDARD','MOVIE','GAME','USER','DYNAMIC(Fixed)','DYNAMIC','PC','STANDARD(3D)','MOVIE(3D)','GAME(3D)','AUTO'],
    :display_order => 4,
    :action => proc{|av_mode|
      send_string "AVMD#{AV_MODE_HASH[av_mode]} \r"
    }

  # The volume must range 0 to 60.
  managed_state_var :volume,
    :type => :number,
    :action => proc{|vol|
      send_string "VOLM#{vol}  \r"
    }

  #The screen position variable randes depend on the view mode or the signal
  # type and can be seen on the position-setting screen. The pos must be a
  # string of length three, so if the number is only 2 digits there must be 
  # a space after it.
  managed_state_var :position,
    :type => :option,
    :options => ['H-POSITION','V-POSITION','CLOCK','PHASE'],
    :action => proc{|pos|
      send_string "#{POS_HASH[pos]} \r"
    }

  managed_state_var :view_mode,
    :type => :option,
    :display_order => 5,
    :options => ['Side Bar[AV]','S.Stretch[AV]','Zoom[AV]','Stretch[AV]','Normal[PC]','Zoom[PC]','Stretch[PC]','Dot by Dot[PC][AV]','Full Screen[AV]','Auto','Original'],
    :action => proc{|mode|
      send_string "WIDE#{VIEW_HASH[mode]}  \r"
    }

  managed_state_var :mute,
    :type => :boolean,
    :action => proc{|on|
      send_string "MUTE#{on ? 1 : 2}   \r"
    }

  managed_state_var :surround,
    :type => :option,
    :options => ['Normal','Off','3D Hall','3D Movie','3D Standard','3D Stadium'],
    :action => proc{|mode|
      send_string "ACSU#{SURROUND_HASH[mode]}   \r"
    }

  managed_state_var :sleep_timer,
    :type => :option,
    :options => ['Off','30min','60min','90min','120min'],
    :action => proc{|time|
      send_string "OFTM#{SLEEP_HASH[time]}   \r"
    }
  
  #In Air, 2-69 is effective. In cable 1-135 is effective. The ch
  # passed to action must be of length 3. Pad with spaces as neccesary.
  managed_state_var :ch_analog,
    :type => :number,
    :action => proc{|ch|
      send_string "DCCH#{ch} \r"
    }

  #0100 to 9999
  managed_state_var :ch_dig_air,
    :type => :number,
    :action => proc{|ch|
      send_string "DCCH#{ch} \r"
    }

  #less than 10,000
  managed_state_var :ch_dig_cable,
    :type => :number,
    :action => proc{|ch|
      send_string "DC10#{ch}\r"
    }

  managed_state_var :three_d,
    :type => :option,
    :display_order => 6,
    :options => ['Off','2D->3D','SBS','TAB','3D-2D(SBS)','3D-2D(TAB)','3D auto','2D auto'],
    :action => proc{|mode|
      send_string "TDCH#{THREE_D_HASH[mode]}   \r"
    }

  # The following are commands corresponding to buttons on the remote
  command :zero_cmd,
    :action => proc{
      send_string "RCKY0   \r"
    }

  command :one_cmd,
    :action => proc{
      send_string "RCKY1   \r"
    }

  command :two_cmd,
    :action => proc{
      send_string "RCKY2   \r"
    }

  command :three_cmd,
    :action => proc{
      send_string "RCKY3   \r"
    }

  command :four_cmd,
    :action => proc{
      send_string "RCKY4   \r"
    }

  command :five_cmd,
    :action => proc{
      send_string "RCKY5   \r"
    }

  command :six_cmd,
    :action => proc{
      send_string "RCKY6   \r"
    }

  command :seven_cmd,
    :action => proc{
      send_string "RCKY7   \r"
    }

  command :eight_cmd,
    :action => proc{
      send_string "RCKY8   \r"
    }

  command :nine_cmd,
    :action => proc{
      send_string "RCKY9   \r"
    }

  command :dot_cmd,
    :action => proc{
      send_string "RCKY10  \r"
    }

  command :ent_cmd,
    :action => proc{
      send_string "RCKY11  \r"
    }

#  command :power_cmd,
#    :action => proc{
#      send_string "RCKY12  \r"
#    }

  command :display_cmd,
    :action => proc{
      send_string "RCKY13  \r"
    }

#  command :pwr_src,
#    :action => proc{
#      send_string "RCKY14  \r"
#    }

  command :back,
    :action => proc{
      send_string "RCKY15  \r"
    }

  command :play,
    :action => proc{
      send_string "RCKY16  \r"
    }

  command :forward,
    :action => proc{
      send_string "RCKY17  \r"
    }

  command :pause,
    :action => proc{
      send_string "RCKY18  \r"
    } 

  command :previous,
    :action => proc{
      send_string "RCKY19  \r"
    } 

  command :stop,
    :action => proc{
      send_string "RCKY20  \r"
    } 
   
  command :next,
    :action => proc{
      send_string "RCKY21  \r"
    }

  command :rec,
    :action => proc{
      send_string "RCKY22  \r"
    } 

  command :option_cmd,
    :action => proc{
      send_string "RCKY23  \r"
    } 

  command :sleep
    :action => proc{
      send_string "RCKY24  \r"
    } 

  command :cc,
    :action => proc{
      send_string "RCKY27  \r"
    } 

  command :av_mode_cmd,
    :action => proc{
      send_string "RCKY28  \r"
    } 

  command :view_mode_cmd,
    :action => proc{
      send_string "RCKY29  \r"
    } 

  command :flashback,
    :action => proc{
      send_string "RCKY30  \r"
    } 

  command :mute_cmd,
    :action => proc{
      send_string "RCKY31  \r"
    } 

  command :dec_vol
    :action => proc{
      send_string "RCKY32  \r"
    } 

  command :inc_vol,
    :action => proc{
      send_string "RCKY33  \r"
    } 

  command :up_ch,
    :action => proc{
      send_string "RCKY34  \r"
    } 

  command :down_ch,
    :action => proc{
      send_string "RCKY35  \r"
    } 

  command :input_cmd,
    :action => proc{
      send_string "RCKY36  \r"
    } 

  command :menu_cmd
    :action => proc{
      send_string "RCKY38  \r"
    } 

  command :smart_central,
    :action => proc{
      send_string "RCKY39  \r"
    } 

  command :enter_cmd,
    :action => proc{
      send_string "RCKY40  \r"
    } 

  command :up_cmd,
    :action => proc{
      send_string "RCKY41  \r"
    } 

  command :down_cmd,
    :action => proc{
      send_string "RCKY42  \r"
    } 

  command :left_cmd,
    :action => proc{
      send_string "RCKY43  \r"
    } 

  command :right_cmd,
    :action => proc{
      send_string "RCKY44  \r"
    } 

  command :return_cmd,
    :action => proc{
      send_string "RCKY45  \r"
    } 

  command :exit_cmd,
    :action => proc{
      send_string "RCKY46  \r"
    } 

  command :fav_ch,
    :action => proc{
      send_string "RCKY47  \r"
    } 

  command :threed_surround,
    :action => proc{
      send_string "RCKY48  \r"
    } 

  command :audio_cmd,
    :action => proc{
      send_string "RCKY49  \r"
    } 

  command :a_red_cmd,
    :action => proc{
      send_string "RCKY50  \r"
    } 

  command :b_green_cmd,
    :action => proc{
      send_string "RCKY51  \r"
    } 

  command :c_blue_cmd,
    :action => proc{
      send_string "RCKY52 \r"
    } 

  command :d_yellow_cmd,
    :action => proc{
      send_string "RCKY53  \r"
    } 

  command :freeze_cmd,
    :action => proc{
      send_string "RCKY54  \r"
    } 

  command :fav_app_1_cmd,
    :action => proc{
      send_string "RCKY55  \r"
    } 

  command :fav_app_2__cmd,
    :action => proc{
      send_string "RCKY56  \r"
    } 

  command :fav_app_3_cmd,
    :action => proc{
      send_string "RCKY57  \r"
    } 

  command :three_d_cmd,
    :action => proc{
      send_string "RCKY58  \r"
    } 

  command :netflix_cmd,
    :action => proc{
      send_string "RCKY59  \r"
    } 

  responses do
    nack :not_ok, "ERR0DH", "Communication error or incorrect command"
    ack :ok, "OK0DH", "Normal response"
  end

  requests do
    send :power,     "POWR?   \r", 1
    send :input,     "IAVD?   \r", .5
    send :av_mode,   "AVMD??? \r", .25
    send :view_mode, "WIDE??  \r", .25
    send :three_d,   "TDCH?   \r", .25
  end

end
