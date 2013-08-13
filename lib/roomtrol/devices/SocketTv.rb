#---
#{
# "name": "SocketTv"
# "depends_on": "SocketDevice",
# "description": "Generic class to control TV over a TCP connection
# "author": "Justin Raymond"
# "email": "jraymond@wesleyan.edu"
# "abstract": true,
# "type": "Tv"
#}
#---

class SocketTv < Wescontrol::SocketDevice

  @interface = "Tv"

  state_var :power, :type => :boolean, :display_order => 1
  state_var :input, :type => :option, :options => ['TV','HDMI 1','HDMI 2','HDMI 3','HDMI 4','COMPONENT','VIDEO 1','VIDEO 2','PC'], :display_order => 2
  #state_var :av_mode, :type => :option, :options => ['STANDARD','MOVIE','GAME','USER','DYNAMIC(fixed)','DYNAMIC','PC','STANDARD(3D)','MOVIE(3D)','GAME(3D)','AUTO']
  state_var :volume, :type => :number
  #state_var :position, :type => :option, :options => ['H-POSITION','V-POSITION','CLOCK','PHASE']
  #state_var :view_mode, :type => :option, :options => ['Side Bar[AV]','S.Stretch[AV]','Zoom[AV]','Stretch[AV]','Normal[PC]','Zoom[PC]','Stretch[PC]','Dot by Dot[PC][AV]','Full Screen[AV]','Auto','Original']
  state_var :mute, :type => :boolean
  #state_var :surround, :type => :option, :options => ['Normal','Off','3D Hall','3D Movie','3D Standard','3D Stadium']
  state_var :channel, :type => :number
  #state_var :threeD, :type => :option, :options => ['3D Off','2D->3D','SBS','TAB','3D->2D(SBS)','3D-2D(TAB)','3D auto','2D auto']
end 
