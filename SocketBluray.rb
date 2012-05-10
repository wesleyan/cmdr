class SocketBluRay < Wescontrol::SocketDevice

  configure do
    DaemonKit.logger.info "@Initializing SocketBluRay at URI #{options[:uri]} with name #{name}"
  end

  command 'play', 
    :type => :command, 
    :action => proc{|command|
      DaemonKit.logger.info "BLURAY: Issuing a play command"
      "PL\r\n"
    }
  command :stop,
    :type => :command,
    :action => proc{|command|
      "99RJ\r\n"
    }

  state_var :operational, :type => :boolean

end
