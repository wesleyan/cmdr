class Computer < Wescontrol::Device
	@interface = "Computer"
	
	def initialize(options)
		@ip_address = options[:ip_address]
		super(options)
	end
	
	config_var :ip_address
	
	#current info
	state_var :reachable, 		:kind => :boolean, 	:editable => false
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
end
