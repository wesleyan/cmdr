require 'chronic'
require 'net/ssh'

class Mac < Computer

	config_var :username
	config_var :password
	
	state_var :logged_in, 		:kind => :boolean, 	:editable => false
	state_var :current_user, 	:kind => :string, 	:editable => false
	state_var :current_app, 	:kind => :string, 	:editable => false
	state_var :uptime, 			:kind => :integer, 	:editable => false
	state_var :logged_in_time, 	:kind => :integer, 	:editable => false
	state_var :idle_time,		:kind => :integer,	:editable => false
	state_var :power,			:kind => :boolean
	
	#computer information
	state_var :name,			:kind => :string, 	:editable => false
	state_var :model,			:kind => :string,	:editable => false
	state_var :os,				:kind => :string, 	:editable => false
	state_var :cpu,				:kind => :string, 	:editable => false
	state_var :cpu_speed,		:kind => :decimal, 	:editable => false
	state_var :cpu_number,		:kind => :integer,	:editable => false
	state_var :hdd_size,		:kind => :decimal, 	:editable => false
	state_var :memory_size,		:kind => :integer, 	:editable => false
	state_var :mac_addr,		:kind => :string,	:editable => false
	
	def initialize(options)
		puts "Initializing Mac on #{self.ip_address}"
		options = options.symbolize_keys

		Thread.abort_on_exception = true
		
		@username = options[:username]
		@password = options[:password]
		
		super(:ip_address => options[:ip_address])
		
		@tasks = {
			:current_user => ['who', proc{|response|
				users = response.split("\n").collect{|x| x.split(/   */).collect{|y| y.strip}}.reject{|x| x[1] != "console"}
				self.current_user = users[0][0]
				self.logged_in = users.size > 0
				self.logged_in_time = (Time.now - Chronic.parse(users[0][2], :context => :past)).round
				#self.idle_time = 
			}],
			:current_app => ['osascript -e "set front_app to (path to frontmost application as Unicode text)"', proc{|response|
				self.current_app = response.strip.split(":")[-1]
			}],
			:uptime => ["uptime", proc{|response|
				t = response[/up.*?,.*?,/]
				days = t[/up \d* days/][/\d+/].to_i
				hours, minutes = t[/\d{1,2}:\d\d/].split(":").collect{|a| a.to_i}
				self.uptime = minutes + (hours + (days * 24)) * 60 #returns number of minutes of uptime
			}],
			:idle_time => ["echo $((`ioreg -c IOHIDSystem | sed -e '/HIDIdleTime/ !{ d' -e 't' -e '}' -e 's/.* = //g' -e 'q'` / 1000000000))", proc{|response|
				self.idle_time = response.to_i
			}]
		}
		
		@information =  {
			:system_information => ["system_profiler -detailLevel basic", proc{|response|
				def value_of(name, response); response[/#{name}:.+/].split(":")[1].strip; end
				self.model 		= value_of "Model Name", response
				self.name 		= value_of "Computer Name", response
				self.os 		= value_of "System Version", response
				self.cpu 		= value_of "Processor Name", response
				self.cpu_speed	= value_of "Processor Speed", response
				self.cpu_number	= value_of "Total Number Of Cores", response
				self.memory_size= value_of "Memory", response
				self.mac_addr	= value_of "MAC Address", response
				
				begin
					self.hdd_size	= response.scan(/Capacity:.*/)[0].split(":")[1].strip
				rescue
				end
			}]
		}
		
		Thread.new {
			while true
				Net::SSH.start(self.ip_address, self.username, :password => self.password) do |ssh|
					process :system_information, ssh, @information
					while true
						@tasks.each_key{|task|
							(process task, ssh).wait
						}
						sleep 5
					end
				end
				ssh.loop
			end
		}
		
	end
	
	def process(call, ssh, source = @tasks)
		ssh.exec source[call][0] do |ch, stream, data|
			begin
				source[call][1].call(data)
			rescue
			end
		end
	end
end