require 'date'
God.watch do |w|
	w.name = "recorder"
	w.interval = 2.seconds
	w.start = "#{File.dirname(__FILE__)}/start-recording"
	w.stop = "killall transcode"
	
	w.start_grace = 5.seconds
	
	w.start_if do |start|
		start.condition(:process_running) do |c|
			c.interval = 2.seconds
			c.running = false
		end
	end  
end