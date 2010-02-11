module MAC
	class << self
		def addr
			return @mac_address if defined? @mac_address and @mac_address
			re = %r/[^:\-](?:[0-9A-F][0-9A-F][:\-]){5}[0-9A-F][0-9A-F][^:\-]/io
			cmds = '/sbin/ifconfig', '/bin/ifconfig', 'ifconfig', 'ipconfig /all'

			null = test(?e, '/dev/null') ? '/dev/null' : 'NUL'

			lines = nil
			cmds.each do |cmd|
			stdout = IO.popen("#{ cmd } 2> #{ null }"){|fd| fd.readlines} rescue next
			next unless stdout and stdout.size > 0
				lines = stdout and break
			end
			raise "all of #{ cmds.join ' ' } failed" unless lines

			candidates = lines.select{|line| line =~ re}
			raise 'no mac address candidates' unless candidates.first
			candidates.map!{|c| c[re].strip}

			maddr = candidates.first
			raise 'no mac address found' unless maddr

			maddr.strip!
			maddr.instance_eval{ @list = candidates; def list() @list end }

			@mac_address = maddr
		end
	end
end
