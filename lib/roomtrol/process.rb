module RoomtrolVideo
	# ProcessMonitor lets you start and monitor system proccesses. Much of this code was inspired
	# by God's process management code.
	class ProcessMonitor
		attr_reader   :pid
		attr_reader   :restarts
		attr_accessor :cmd
		
		# Creates a new process monitor for the process started by running
		# the supplied command
		# @param [String] cmd The command to run
		def initialize(cmd)
			@cmd = cmd
			@restarts = 0
			@run_once = false
		end 
		
		# Kills the process, by force if neccessary
		def kill
			5.times{|time|
				begin
					Process.kill(2, pid)
				rescue Errno::ESRCH
					return
				end
				sleep 0.1
			}
		
			Process.kill('KILL', @pid) rescue nil
		end
	
		# Checks whether or not the process is still running
		# @return [TrueClass] true if the process is still running, false otherwise
		def alive?
			#double exclamation mark returns true for a non-false values
			!!Process.kill(0, @pid) rescue false
			@restarts = 0
		end
	
		# Starts the process by running the command
		# @return [Fixnum] the pid of the process
		def start
			@restarts += 1 if @run_once
			r, w = IO.pipe
			begin
				outside_pid = fork do
					STDOUT.reopen(w)
					r.close
					pid = fork do
						#Process.setsid
						#Dir.chdir '/'
						$0 = @cmd
						STDIN.reopen("/dev/null")
						STDOUT.reopen("/dev/null")
						STDERR.reopen(STDOUT)
						3.upto(256){|fd| IO.new(fd).close rescue nil}
						exec cmd
					end
					puts pid.to_s
				end
				Process.waitpid(outside_pid, 0)
				w.close
				pid = r.gets.chomp.to_i
				puts "Parent: #{pid}"
			ensure
				r.close rescue nil
				w.close rescue nil
			end
			@run_once = true
			@pid = child_pids(pid)[0].to_i
		end
	
		private
		def child_pids pid
			`ps -ef | grep #{pid}`.split("\n").collect{|line| line.split(/\s+/)}.reject{|parts| 
				parts[2] != pid.to_s || parts[-2] == "grep"
			}.collect{|parts| parts[1]}
		end
	end
end