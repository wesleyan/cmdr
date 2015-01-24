require 'strscan'
require 'rubybits'
require 'xmlrpc/client'
require 'cmdr/communication'
module Cmdr
  class CommDevice < Device
    attr_accessor :commclient

    def initialize(name, options, db_uri='http://localhost:5984/rooms')
      configure do
        message_end "\r"
        message_timeout 0.2
        message_delay 1
      end
      Thread.abort_on_exception = true

      options = options.symbolize_keys
      super(name, options, db_uri)

      @_send_queue = []
      @_ready_to_send = true
      @_last_time_sent = Time.at(0)
      @_waiting = false
    end

    def send_string(string)
      raise NotImplementedError
    end

    def connect
      raise NotImplementedError
    end

    def handle_connection_error
      DaemonKit.logger.error "Connection failed: #{$!}"
    end

    def run
      EM::run {
        begin
          ready_to_send = true
          @_ready_to_send_timer = EM::add_periodic_timer configuration[:message_timeout] do
            self.ready_to_send = @_ready_to_send
          end
          @_conn = self.connect
          @_conn.stream {|data| read data }
        rescue
          self.handle_connection_error
        end
        super
      }
    end

    def self.managed_state_var name, options
      throw "Must supply a proc to :action" unless options[:action].is_a? Proc
      state_var name, options
      define_method "set_#{name}".to_sym, proc {|value|
        message = instance_exec(value, &options[:action])
        deferrable = EM::DefaultDeferrable.new
        do_message message, deferrable
        deferrable
      }    
    end

    def do_message(message, deferrable = nil)
      @_send_queue ||= []
      @_send_queue.unshift [message, deferrable]
    end

    class ResponseHandler
      attr_reader :matchers
      def initialize
        @matchers = []
      end
      def match name, matcher, interpreter
        @matchers << [name, matcher, interpreter]
      end
      def ack matcher
        @matchers << [:ack, matcher]
      end
      def nack matcher
        @matchers << [:nack, matcher]
      end
      def error name, matcher, message = nil
        @matchers << [:error, matcher, message]
      end
    end

    def self.responses &block
      rh = ResponseHandler.new
      block.arity < 1 ? rh.instance_eval(&block) : block.call(rh)
      @_matchers ||= []
      @_matchers += rh.matchers if rh.matchers
    end
    
    def matchers
      self.class.instance_variable_get(:@_matchers)
    end
    
    class RequestHandler
      attr_reader :requests
      def send name, req, freq
        @requests ||= []
        @requests << [name, req, freq]
      end
    end

    def self.requests &block
      rh = RequestHandler.new
      block.arity < 1 ? rh.instance_eval(&block) : block.call(rh)
      
      @_requests ||= []
      @_requests += rh.requests
      @_request_scheduler = []
      #The multiplier is the number which scales everything such that
      #the smallest is 1.0
      multiplier = 1.0/@_requests.collect{|x| x[2]}.min
      #Multiply all of the priorities by the multiplier
      r = @_requests.collect{|x| [x[0], x[1], (x[2]*multiplier).to_i]}
      iter = 0
      r.inject(0){|sum, x|x[2] + sum}.times{|i|
        while r[iter % r.size][2] == 0
          iter += 1
        end
        r[iter % r.size][2] -= 1
        @_request_scheduler << r[iter % r.size]
        iter += 1
      }
    end

    def request_scheduler
      self.class.instance_variable_get(:@_request_scheduler)
    end

    def unless_operational
    	self.operational = true
    end

    def lost_communication
    end

    def prescan data
    	data
    end

    def do_message_end data, handle_message, message_received
      loop_message_received = false
      if instance_exec(data, &configuration[:mesaage_end])
        handle_message.call(data)
        loop_message_received = true
        message_received |= loop_message_received
      end
      return loop_message_received, message_received
    end
    end

    def me_message_received ready
    	ready
    end

    def read data
      EventMachine.cancel_timer @_timer if @_timer
      unless self.operational
        self.unless_operational
      end
      @_timer = EventMachine.add_timer(10) do
        DaemonKit.logger.error("Lost communication with #{@name}")
        self.operational = false
        EventMachine.cancel_timer @_timer
        self.lost_communication
      end
      @_responses ||= {}
      to_scan = self.prescan(data)
      s = StringScanner.new(to_scan)
      handle_message = proc {|msg|
        m = matchers.find{|matcher|
          case matcher[1].class.to_s
            when "Regexp" then msg.match(matcher[1])
            when "Proc" then matcher[1].call(msg)
            when "String" then matcher[1] == msg
          end
        } if matchers
        if m
          arg = msg
          arg = msg.match(m[1]) if m[1].is_a? Regexp
          if @_message_handler
            case m[0]
              when :ack then
                @_message_handler.succeed
              when :nack then
                @_message_handler.fail
              when :error then
                resp = m[2].is_a?(Proc) ? instance_exec(arg, &m[2]) : m[2]
                @_message_handler.fail resp
              else
                @_message_handler.succeed instance_exec(arg, &m[2])
            end
            @_message_handler = nil
          elsif m[2].is_a? Proc
            instance_exec(arg, &m[2])
          end
          !configuration[:wait_until_ack] || (m[0] == :ack || m[0] == :nack)
        end
      }
      message_received = false
      if configuration[:message_format].is_a? Regexp
        while msg = s.scan(configuration[:message_format]) do
          handle_message.call(msg.match(configuration[:message_format])[1])
        end
      elsif configuration[:message_end].is_a? Proc
        loop do
          loop_message_received, message_received = self.do_message_end data, handle_message, message_received
          break unless loop_message_received
        end
      elsif me = configuration[:message_end]
        regex = /.*?#{me}/
        while msg = s.scan(regex) do
          msg.gsub!(me, "")
          ready = handle_message.call(msg)
          message_received = self.me_message_received ready
        end
        @_buffer = s.rest
      end
      #if we got the message end signal, we're safe to send the next thing
      if message_received
        self.ready_to_send = true
      end
    end

    def ready_to_send=(state)
      @_ready_to_send = state
      if Time.now - @_last_sent_time > configuration[:message_timeout]
        DaemonKit.logger.debug("#{self.name}: Request timed out") unless state
        @_ready_to_send = true
      end
      if @_ready_to_send && !@_waiting
        @_waiting = true
        @_request_timer = EM::add_timer(configuration[:message_delay]) do
          if @_send_queue.size == 0
            request = choose_request
            do_message request if request
          end
          send_from_queue
          @_waiting = false
        end
      end
    end

    def ready_to_send; @_ready_to_send; end

    def send_from_queue
      if message = @_send_queue.pop
        @_last_sent_time = Time.now
        @_message_handler = message[1] ? message[1] : EM::DefaultDeferrable.new
        @_message_handler.timeout(configuration[:message_timeout])
        send_string message[0]
      end
    end

    def choose_request
      return nil unless request_scheduler
      @_request_iter ||= -1
      @_request_iter += 1
      request_scheduler[@_request_iter % request_scheduler.size][1]
    end
  end
end
