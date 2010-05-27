require 'ping'

class Printer < Computer
	@interface = "Printer"
	
	config_var :ip_address
	
	#current info
	state_var :pages_remaining, 	:kind => :integer, 	:editable => false
	state_var :toner_low,			:kind => :boolean, 	:editable => false
	state_var :toner_out,			:kind => :boolean,	:editable => false
	state_var :paper_out,			:kind => :boolean,	:editable => false
	state_var :toner_remaining,		:kind => :percentage, :editable => false
	state_var :jammed,				:kind => :boolean, 	:editable => false
	state_var :page_count,			:kind => :integer, 	:editable => false
	
	#other
	state_var :model,				:kind => :string,	:editable => false
	state_var :serial_number,		:kind => :string,	:editable => false
	state_var :memory,				:kind => :integer,	:eidtable => false
	
	def initialize(options)
		super(options)

		
	end
	
end
