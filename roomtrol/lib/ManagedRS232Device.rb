require 'strscan'
module Wescontrol
	class ManagedRS232Device < RS232Device
		configure do
			message_end "\r\n"
		end
		def self.state_var name, options
			#throw "Must have :action field of type Proc" unless options[:action].class == Proc
			#throw "Must have :response field" unless options[:response]
			super name, options
		end
		
		class ResponseHandler
			attr_reader :matchers
			def match name, matcher, interpreter
				@matchers ||= []
				@matchers << [name, matcher, interpreter]
			end
		end
		def self.responses &block
			rh = ResponseHandler.new
			rh.instance_eval(&block)
			@matchers ||= []
			@matchers += rh.matchers if rh.matchers
		end
		def matchers
			self.class.instance_variable_get(:@matchers)
		end
		
		def read data
			@buffer ||= ""
			@buffer << data
			s = StringScanner.new(@buffer)
			while msg = s.scan(/.+?#{configuration[:message_end]}/) do
				msg.gsub!(configuration[:message_end], "")
				m = matchers.find{|matcher|
					result = case matcher[1].class.to_s
						when "Regexp" then msg.match(matcher[1])
						when "Proc" then matcher[1].call(msg)
						when "String" then matcher[1] == msg
					end
				} if matchers
				instance_exec(msg, &m[2]) if m
			end
			@buffer = s.rest
		end
	end
end