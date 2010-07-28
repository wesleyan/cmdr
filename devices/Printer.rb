#---
#{
#	"name": "Printer",
#	"depends_on": "Computer",
#	"description": "Generic class for printer monitoring.",
#	"author": "Micah Wylde",
#	"email": "mwylde@wesleyan.edu",
#	"abstract": true,
#	"type": "Printer"
#}
#---

class Printer < Computer

	configure do
		ip_address :type => :string
	end
	
	#current info
	state_var :pages_remaining,     :type => :integer,  :editable => false
	state_var :toner_low,           :type => :boolean,  :editable => false
	state_var :toner_out,           :type => :boolean,  :editable => false
	state_var :paper_out,           :type => :boolean,  :editable => false
	state_var :toner_remaining,     :type => :percentage, :editable => false
	state_var :jammed,              :type => :boolean,  :editable => false
	state_var :page_count,          :type => :integer,  :editable => false
	
	#other
	state_var :model,               :type => :string,   :editable => false
	state_var :serial_number,       :type => :string,   :editable => false
	state_var :memory,              :type => :integer,  :eidtable => false
	
	def initialize(options)
		super(options)
	end
	
end
