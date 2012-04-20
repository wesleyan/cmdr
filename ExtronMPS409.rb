class ExtronMPS409 < ExtronVideoSwitcher
  AUDIO_HASH = {1 => "1*1", 2 => "1*2", 3 => "2*1", 4 => "2*2", 5 => "3*1", 6 => "3*2", 7 => "3*3", 8 => "4*1", 9 => "4*2"}

  managed_state_var :video,
    :type => :option,
    :display_order => 1,
    :options => ("1".."6").to_a,
    :response => :channel,
    :action => proc{|input|
      "#{input}!"
  }
  managed_state_var :audio,
    :type => :option,
    :display_order => 2,
    :options => ("1".."6").to_a,
    :response => :channel,
    :action => proc{|input|
      "#{AUDIO_HASH[input]}$"
  }

  responses do
    match :audio, /Mod(\d+) (\d)G(\d) (\d)G(\d) (\d)G(\d) (\d)G(\d)=(\d)G(\d)/, proc{|m|
      x1, x2 = [m[10].to_i, m[11].to_i]
      self.audio = "#{x1}*#{x2}"
    }
    match :video, /Mod(\d+) (\d)G(\d) (\d)G(\d) (\d)G(\d) (\d)G(\d)=(\d)G(\d)/, proc{|m|
      for i in (1..4)
        if m[2*i+1] != 0
          v1, v2 = [m[2*i].to_i, m[2*i+1].to_i]
          break
        end
      end
      self.video = (v1 < 3 ? ((v1-1)*2 + (v2-1) % 2 + 1) : ((v1-3)*3 + (v2-1) % 3 + 5))
    }
    end
end
