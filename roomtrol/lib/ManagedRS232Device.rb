module Wescontrol
	class ManagedRS232Device < RS232Device
		@matchers = []
		def self.state_var name, options
			#throw "Must have :action field of type Proc" unless options[:action].class == Proc
			#throw "Must have :response field" unless options[:response]
			super name, options
		end
		
		class ResponseHandler
			def match name, matcher, interpreter
				return [name, matcher, interpreter]
			end
		end
		def self.responses &block
			@matchers << ResponseHandler.new.instance_eval(&block)
		end
		
		def read data
		end
	end
end