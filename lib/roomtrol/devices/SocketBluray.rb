class SocketBluray < Wescontrol::SocketDevice

  configure do
    DaemonKit.logger.info "@Initializing SocketBluray at URI #{options[:uri]} with name #{name}"
  end

  command :play, 
      :action => proc{
      send_string "PL\r\n"
  }
  command :stop,
    :action => proc{
      send_string "99RJ\r\n"
    }
  command :pause,
    :action => proc{
      send_string "ST\r\n"
    }
  command :forward,
    :action => proc{
      send_string "NF\r\n"
    }
  command :back,
    :action => proc{
      send_string "NR\r\n"
    }
  command :next,
    :action => proc{
      #send_string "SF\r\n"
      send_string "/A181AF3D/RU\r\n"
    }
  command :previous,
    :action => proc{
      #send_string "SR\r\n"
      send_string "/A181AF3E/RU\r\n"
    }
  command :title,
    :action => proc{
      send_string "/A181AFB9/RU\r\n"
    }
  command :menu,
    :action => proc{
      send_string "/A181AFB4/RU\r\n"
    }
  command :up,
    :action => proc{
      send_string "/A184FFFF/RU\r\n"
    }
  command :right,
    :action => proc{
      send_string "/A186FFFF/RU\r\n"
    }
  command :down,
    :action => proc{
      send_string "/A185FFFF/RU\r\n"
    }
  command :left,
    :action => proc{
      send_string "/A187FFFF/RU\r\n"
    }
  command :enter,
    :action => proc{
      send_string "/A181AFEF/RU\r\n"
    }
  command :eject,
    :action => proc{
      send_string "/A181AFB6/RU\r\n"
    }


  state_var :operational, :type => :boolean

  requests do
    send :ping, "\r\n", 1.0
    send :time, "?T\r\n", 0.1
  end

end
