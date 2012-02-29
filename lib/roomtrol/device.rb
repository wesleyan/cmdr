require 'couchrest'
require 'json'

module Wescontrol
  # Device provides a DSL for describing devices of all
  # kinds. Anything that can be controlled by a computer--whether by
  # IR, serial, ethernet, or laser pulse--can be described by this
  # DSL. Furthermore, in order to be part of the Roomtrol system, a
  # device _must_ be implemented as a Device. New devices are created
  # by either subclassing Device directly or by subclassing one of its
  # child classes, like RS232Device, Projector, or VideoSwitcher. If
  # there exists a class like Projector which describes the category
  # of devices that your device is pat of you should subclass it
  # instead of Device directly.  Doing so will give your projector the
  # same basic interface as every other, making it easy to exchange
  # for another. With Device, all of the details of communicating with
  # the outside world and updating the database are taken care of for
  # you, letting you focus on just implementing the device's features.
  # 
  # #Device Variables
  #
  # The basis for this DSL is the concept of state variables, defined
  # by the state_var method.  State vars are--as their name
  # suggests--variables that track the state of something about the
  # device. For example, a projector device might have have a state
  # var "power," which is true if the projector is on and false if the
  # projector is off. There are two kinds of state vars: those that
  # are immutable (e.g., the model number of the projector) and those
  # that are mutable (e.g., the aforementioned power state var).
  # Mutability is specified when the state var is created by the
  # :editable parameter, which defaults to true. Note that even an
  # immutable state var can be changed programatically by calling its
  # `device.varname=` method, but controls for it will not be created
  # in the web interface. For mutable vars you are responsible for
  # creating a method called set_varname, which takes in one argument
  # of the type specified and which should affect the device in such a
  # way as to transition it to the state described by the argument.
  # Alternatively, by passing a Proc to the :action parameter,
  # state_var will create the set method for you. State vars can be
  # created by placing a line like this in your class body:
  # 
  #   state_var power, :type => :boolean
  # 
  # The type field is mandatory, but there are various other optional
  # parameters which are described in the {Device::state_var} method
  # definition.
  # 
  # However, not every action on a device fits into the state var
  # paradigm, though you should try to use it if possible. For
  # example, a camera may have a "zoom in" and "zoom out" feature, but
  # no way to set the zoom level directly. In these cases, a command
  # can be used instead. Calling a command sends a message to the
  # device class but does not include any state information. To
  # declare a command, the syntax below should be used:
  # 
  #   command zoom_in
  # 
  # In addition, you should create a method with the same name as the
  # command (zoom_in in this case) which does the actual work of
  # sending the command to the device. Command also has many options,
  # which can be found in the {Device::command} method definition.
  # 
  # Rounding out the trio of variable types, we have
  # virtual_var. Virtual var is in some ways the opposite of command:
  # instead of providing only control, it provides only
  # information. More importantly, it is not set directly, but is
  # computed from one or more other variables. The purpose of this is
  # primarily to provide useful information for the web interface to
  # display. For example, a projector may report the number of hours a
  # lamp has been in use as well as the percentage of the lamp's life
  # that is gone. However, the more useful metric for somebody
  # evaluating when the lamp needs to be replaced is the number of
  # hours that are left before the lamp dies. We can use simple
  # algebra and a virtual var to compute this information:
  # 
  #   virtual_var :lamp_remaining, :type => :string, :depends_on => [:lamp_hours, :percent_lamp_used], :transformation => proc {
  #     "#{((lamp_hours/percent_lamp_used - lamp_hours)/(60*60.0)).round(1)} hours"
  #   }
  # 
  # Virtual vars are updated whenever the variables they depend on
  # (which can be either state vars or other virtual vars) are
  # updated.
  # 
  # #Configuration
  # Configuration is defined by a configure block, like this, from RS232Device:
  # 
  #   configure do
  #     port :type => :port
  #     baud :type => :integer, :default => 9600
  #     data_bits 8
  #     stop_bits 1
  #     parity 0
  #     message_end "\r\n"
  #   end
  # 
  # Here we can see two kind of configuration statements: system
  # defined and user defined.  The first two, port and baud, are user
  # defined, while the rest are system defined. User defined config
  # vars are intended to be set by the user in the web interface. The
  # type parameter is a hint to the web interface about what kind of
  # control to show and what kind of validation to do on the
  # input. For example, setting a type of :port will display a
  # drop-down of the serial ports defined for the system. A type of
  # :integer will display a text box whose input is restricted to
  # numbers. Other possibilities are :password, :string, :decimal,
  # :boolean and :percentage. If you supply a type that is not defined
  # in the system, a simple text box will be used. An optional
  # :default parameter can be used to set the initial value.
  # 
  # System defined config vars, on the other hand, are not modifiable
  # by the user. They are specified in the device definition (as can
  # be seen here) and cannot change. You can add whatever
  # configuration variables you need, though they should be named
  # using lowercase letters connected\_by\_underscores. Configuration
  # information is accessible through the {Device#configuration}
  # method, which returns a hash mapping between a symbol of the name
  # to the value. More information in the {Device::configure} method
  # definition.
  # 
  # #Controlling Devices
  #
  # Devices are controlled externally through the use of a message
  # queue which speaks the [AMQP](http://www.amqp.org/) protocol. At
  # the moment we use [RabbitMQ](http://www.rabbitmq.com/) as the
  # message broker, but technically everything should work with
  # another broker and RabbitMQ should not be assumed. AMQP is a very
  # complicated protocol which can support several different messaging
  # strategies. The only one used here is the simplest: direct
  # messaging, wherein there is one sender and one recipient. AMQP
  # messages travel over "queues," which are named structures that
  # carry messages in one direction. Each device has a queue, named
  # roomtrol:dqueue:{name} (replace {name} with the actual name of the
  # device), which it watches for messages. Messages are JSON
  # documents with at least three pieces of information: a unique ID
  # (GUIDs are recommended to ensure uniqueness), a response queue
  # which the sender is watching, and a type. The device will carry
  # out the instructions in the message and send the response as a
  # json message to the queue specified.
  # 
  # ##Messages
  # There are three kinds of messages one can send to a device:
  # 
  # ###state_get To get information about the current state of a
  # variable, send a state_get message, which looks like the
  # following:
  # 
  #   !!!json
  #   {
  #     id: "DD2297B4-6982-4804-976A-AEA868564DF3",
  #     queue: "roomtrol:http"
  #     type: "state_get",
  #     var: "input"
  #   }
  # 
  # A state_get message returns a response like the following:
  # 
  #   !!!json
  #   {
  #     id: "DD2297B4-6982-4804-976A-AEA868564DF3",
  #     result: 5 
  #   }
  # 
  # ###state_set
  # To set a state_var, send a state_set message
  # 
  #   !!!json
  #   {
  #     id: "D62F993B-E036-417C-948B-FEA389480984",
  #     queue: "roomtrol:websocket"
  #     type: "state_set",
  #     var: "input",
  #     value: 4
  #   }
  # 
  # The response will look like this:
  # 
  #   !!!json
  #   {
  #     "id": "FF00F317-108C-41BD-90CB-388F4419B9A1",
  #     "result": true
  #   }
  # 
  # ###command
  # To send a command to a device, use this:
  # 
  #   !!!json
  #   {
  #     id: "FF00F317-108C-41BD-90CB-388F4419B9A1",
  #     queue: "roomtrol:http"
  #     type: "command",
  #     method: "power",
  #     args: [true]
  #   }
  # 
  # Which will produce a response like:
  # 
  #   !!!json
  #   {
  #     "id": "FF00F317-108C-41BD-90CB-388F4419B9A1",
  #     "result": "power=true"
  #   }
  # 
  # Any of these calls can also produce an error. Error responses look like this:
  # 
  #   !!!json
  #   {
  #     "id": "FF00F317-108C-41BD-90CB-388F4419B9A1",
  #     "error": "Failed to turn projector on"
  #   }
  # 
  # This and the rest of the documentation here should cover
  # everything you need to know to write Device subclasses. More
  # information can also be found in the tests, which define exactly
  # what the device class must do and not do.
  class Device

    # The id in CouchDB for this device
    attr_accessor :_id
    # The rev in CouchDB for this device
    attr_accessor :_rev
    # The id of the room this device is in
    attr_accessor :belongs_to
    # The id of the controller that controls this device
    attr_accessor :controller
    # The name of the device
    attr_reader :name
    # The queue that the device watches for messages
    attr_reader :dqueue

    # Creates a new Device instance
    #
    # @param [Hash{String, Symbol => Object}] hash A hash of
    #   configuration definitions, from the name of the config var to
    #   its value
    # @param [String] db_uri The URI of the CouchDB database where
    #   updates should be saved
    def initialize(hash = {}, db_uri = "http://localhost:5984/rooms")
      hash_s = hash.symbolize_keys
      hash.each{|var, value|
        configuration[var.to_sym] = value
      } if configuration
      #TODO: The database uri should not be hard-coded
      @db = CouchRest.database(db_uri)
    end

    # Run is a blocking call that starts the device. While run is
    # running, the device will watch for 0MQ events as well as
    # whatever communication channels the device uses and react
    # appropriately to events.
    #
    # @param [String] path The path to bind our 0MQ socket to
    def run path
      ctx = EM::ZeroMQ::Context.new(1)

      EM.run {
        handle_feedback = proc {|feedback, req, resp, job|
          if feedback.is_a? EM::Deferrable
            feedback.callback do |fb|
              resp["result"] = fb
            end
            feedback.errback do |error|
              resp["error"] = error
            end
          elsif !feedback.nil?
            resp["result"] = feedback
          end
          resp
        }

        DaemonKit.logger.info("Waiting for messages on #{path}")
        subscriber = ZMQClient.new
        subscriber.subscribe_multi{|socket, messages|
          msg = begin
                  req = JSON.parse(messages.pop)
                  resp = {:id => req["id"]}
                  case req["type"]
                  when "command"
                    handle_feedback.call(self.send(req["method"], *req["args"]),
                                         req, resp)
                  when "state_set"
                    DaemonKit.logger.debug("Doing state_set #{req["var"]} = #{req["value"]}")
                    handle_feedback.call(self.send("set_#{req["var"]}", req["value"]),
                                         req, resp)
                  when "state_get"
                    handle_feedback.call(self.send(req["var"]), req, resp)
                  else
                    DaemonKit.logger.error "Didn't match: #{req["type"]}"
                    nil
                  end

                rescue
                  resp[:error] = $!
                  handle_feedback.call(nil, req, resp)
                end
          args = messages + [msg.to_json]
          socket.send_msg(*args)
        }
        ctx.bind(ZMQ::ROUTER, path, subscriber)

        @event_socket = ctx.connect(ZMQ::PUSH, PUB_PATH)
      }
    end

    # @private
    # This is a hook that gets called when the class is subclassed.
    # we need to do this because otherwise subclasses don't get a parent
    # class's state_vars
    def self.inherited(subclass)
      subclass.instance_variable_set(:@state_vars, {})
      self.instance_variable_get(:@state_vars).each{|name, options|
        subclass.class_eval do
          state_var(name, options.deep_dup)
        end
      } if self.instance_variable_get(:@state_vars)

      subclass.instance_variable_set(:@_configuration, @_configuration)
      subclass.instance_variable_set(:@_var_affects, @_var_affects)

      self.instance_variable_get(:@command_vars).each{|name, options|
        subclass.class_eval do
          command(name, options.deep_dup)
        end
      } if self.instance_variable_get(:@command_vars)
    end

    # @return [Hash{Symbol => Object}] A map from config var name to value
    def self.configuration
      @_configuration
    end

    # @return [Hash{Symbol => Object}] A map from config var name to value
    def configuration
      self.class.instance_variable_get(:@_configuration)
    end

    # @return [Hash{Symbol => Hash}] A map from config var name to a hash containing
    #   information about the config var, as passed in to config when the var was
    #   created.
    def config_vars
      self.class.instance_variable_get(:@config_vars)
    end

    # @private
    # A simple class which has no methods defined and therefore is good
    # for parsing configuration. Basically, by having this class eval
    # the configuration block, we can implement a blanket method_missing
    # which will catch everything.
    class ConfigurationHandler
      attr_reader :configuration
      attr_reader :config_vars
      def initialize
        @configuration = {}
        @config_vars = {}
      end
      def method_missing name, args = nil
        if args.is_a? Hash
          @configuration[name] = args[:default]
          @config_vars[name] = args
        else
          @configuration[name] = args
          @config_vars[name] = {:value => args}
        end
      end
    end

    # Starts a configuration block, wherein you can define config
    # vars. Inside of the block should be lines describing the
    # configuration of the device. There are two kinds of config
    # variables you can define: user defined and system defined. User
    # defined config vars are intended to be set by the user in the
    # web interface, whereas system defined config variables are given
    # a value when created and cannot be modified by the user. This
    # should be used for defining things that are intrinsic to the
    # device, like RS232 connection parameters (i.e., data bits, stop
    # bits, parity). Defining a system defined config variable is very
    # simple: all it takes is the name and the value, on the same
    # line. A user defined config variable has two options, which are
    # given as parameters: the type and an optional default value. The
    # type parameter is a hint to the web interface about what kind of
    # control to show and what kind of validation to do on the
    # input. For example, setting a type of :port will display a
    # drop-down of the serial ports defined for the system. A type of
    # :integer will display a text box whose input is restricted to
    # numbers. Other possibilities are :password, :string, :decimal,
    # :boolean and :percentage. If you supply a type that is not
    # defined in the system, a simple text box will be used.
    #
    # You can add whatever configuration variables you need, though
    # they should be named using lowercase letters
    # connected\_by\_underscores. Configuration information is
    # accessible through the {Device#configuration} method, which
    # returns a hash mapping between a symbol of the name to the
    # value.
    # 
    # @example
    #   configure do
    #     port :type => :port
    #     baud :type => :integer, :default => 9600
    #     data_bits 8
    #     stop_bits 1
    #     parity 0
    #     message_end "\r\n"
    #   end
    def self.configure &block
      ch = ConfigurationHandler.new
      ch.instance_eval(&block)
      @_configuration ||= {}
      @config_vars ||= {}
      @_configuration = @_configuration.merge ch.configuration
      @config_vars = @config_vars.merge ch.config_vars
    end

    # @return [Hash{Symbol => Hash}] A map from state var name to a
    #   hash containing information about the state var, as passed in
    #   to state_var when the var was created.
    def self.state_vars; @state_vars; end

    # @return [Hash{Symbol => Array[Symbol]}] A map from a state var
    # name to the list of virtual variables which depend on that state
    # var's value.
    def self.var_affects; @_var_affects; end

    # This method, when called in a class definition, defines a new
    # state variable for the device class. State vars are--as their
    # name suggests--variables that track the state of something about
    # the device. For example, a projector device might have have a
    # state var "power," which is true if the projector is on and
    # false if the projector is off. There are two kinds of state
    # vars: those that are immutable (e.g., the model number of the
    # projector) and those that are mutable (e.g., the aforementioned
    # power state var).  Mutability is specified when the state var is
    # created by the :editable parameter, which defaults to true. Note
    # that even an immutable state var can be changed programatically
    # by calling its device.state_var= method, but controls for it
    # will not be created in the web interface.
    # 
    # Calling state_var can do a number of things. In every case, it
    # will create a getter method for the variable with the name
    # passed in, so that instances of your class will respond to
    # #var_name. It will also create a setter method `#varname=` which
    # should be used to update the state. You should always use the
    # setter to change state rather than access the instance variable
    # directly because the setter will report changes to the database,
    # which is neccessary for any user interface to update. It also
    # forces recalculation on any virtual variables that are defined
    # in terms of a particular state var. In addition to creating
    # accessor methods, if supplied an :action parameter state_var
    # will create a set_varname method using the proc supplied.
    #
    # @param [Symbol] name The name for the state var. Should follow
    #   the general naming conventions: all lowercase, with multiple
    #   words connected\_by\_underscores.
    # @param [Hash] options Options for configuring the state_var
    # @option options [Symbol] :type [mandatory] the type of the
    #   variable; this is used by the web interface to decide what
    #   kind of interface to show. Possible values are :boolean,
    #   :string, :percentage, :number, :decimal, :option, and :array.
    # @option options [Boolean] :editable (true) whether or not this
    #   variable can be set by the user.
    # @option options [Integer] :display_order Used by the web
    #   interface to decide which variables are visible and in which
    #   order they are displayed. For a particular device, the var
    #   with the lowest :display_order is ranked highest, followed by
    #   the next lowest up to 6. Leave out if the variable should not
    #   be shown.
    # @option options [Array<#to_json>] :options If :option is
    #   selected for type, the elements in this array serve as the
    #   allowable options.
    # @option options [Proc] :action If a proc is supplied to :action,
    #   then state_var will automatically create a set_varname method
    #   (where varname is the name of the state variable) which
    #   executes the code provided. The difference between the
    #   set_varname method and `#varname=` method is this: the former
    #   is used to actually change the state of the device (i.e., it
    #   sends a command to the device that ideally results in it
    #   entering the desired state) whereas the latter informs
    #   roomtrol the actual state of the device.
    # @example
    #   state_var :input, 
    #     :type => :option, 
    #     :display_order => 1, 
    #     :options => ("1".."6").to_a,
    #     :action => proc{|input|
    #       send "{input}!\r\n"
    #     }
    def self.state_var name, options
      sym = name.to_sym
      self.class_eval do
        raise "Must have type field" unless options[:type]
        @state_vars ||= {}
        @state_vars[sym] = options
        @_var_affects ||= {}
      end

      self.instance_eval do
        all_state_vars = @state_vars
        define_method("state_vars") do
          all_state_vars
        end
        all_var_affects = @_var_affects
        define_method("var_affects") do
          all_var_affects
        end
      end

      self.class_eval %{
        def #{sym}= val
          if @#{sym} != val
            old_val = @#{sym}
            @#{sym} = val
            DaemonKit.logger.debug sprintf("%-10s = %s\n", "#{sym}", val.to_s)
            if virtuals = self.var_affects[:#{sym}]
              virtuals.each{|var|
                DaemonKit.logger.debug "Doing transform on \#{var}"
                begin
                  transformation = self.instance_eval &state_vars[var][:transformation]
                  self.send("\#{var}=", transformation)
                rescue
                  DaemonKit.logger.error "Transformation on \#{var} failed: \#{$!}"
                end
              }
            end
            if @change_deferrable
              @change_deferrable.set_deferred_status :succeeded, "#{sym}", val
              @change_deferrable = nil

              if @auto_register
                @auto_register.each{|block|
                  register_for_changes.callback(&block)
                }
              end
            end
            self.save('#{sym}', old_val)
          end
          val
        end
        def #{sym}
          @#{sym}
        end
      }

      if options[:action].class == Proc
        define_method "set_#{name}".to_sym, &options[:action]
      end
    end

    # This method, when called in a class definition, creates a new
    # virtual variable. A virtual variable is one that cannot be set
    # directly, but which is composed automatically from one or more
    # other variables (either virtual or not). The purpose of this is
    # primarily to provide useful information for the web interface to
    # display. For example, a projector may report the number of hours
    # a lamp has been in use as well as the percentage of the lamp's
    # life that is gone. However, the more useful metric for somebody
    # evaluating when the lamp needs to be replaced is the number of
    # hours that are left before the lamp dies. We can use simple
    # algebra and a virtual var to compute this information, as seen
    # in the example. Virtual vars are updated whenever the variables
    # they depend on either state vars or other virtual vars) are
    # updated.
    # @param [Symbol] name The name for the virtual var. Should follow
    #   the general naming convention: all lowercase, with multiple
    #   words connected\_by\_underscores.
    # @param [Hash] options Options for configuring the virtual var
    # @option options [Array<Symbol>] :depends_on [mandatory] An array
    #   of the variables' names that this one depends on. Note that
    #   these must have been defined already.
    # @option options [Proc] :transformation [mandatory] A proc with
    #   arity 0 which is run in the context of the device instance
    #   (which means you have access to instance variables and
    #   methods). This proc will be called whenever one of the
    #   constituent variables changes, and should return the new value
    #   of the virtual variable.
    # @option options [Integer] :display_order Used by the web
    #   interface to decide which variables are visible and in which
    #   order they are displayed. For a particular device, the var
    #   with the lowest :display_order is ranked highest, followed by
    #   the next lowest up to 6. Leave out if the variable should not
    #   be shown.
    # @example
    #   virtual_var :lamp_remaining, :type => :string, :depends_on => [:lamp_hours, :percent_lamp_used], :transformation => proc {
    #     "#{((lamp_hours/percent_lamp_used - lamp_hours)/(60*60.0)).round(1)} hours"
    #   }
    def self.virtual_var name, options
      raise "must have :depends_on field" unless options[:depends_on]
      raise "must have :transformation field" unless options[:transformation].class == Proc
      options[:editable] = false
      self.state_var(name, options)
      self.class_eval do
        options[:depends_on].each{|var|
          @_var_affects[var] ||= []
          @_var_affects[var] << name
        }
      end
    end

    # @return [Hash{Symbol => Object}] A map from command name to options
    def self.commands; @command_vars; end

    # @return [Hash{Symbol => Object}] A map from command name to options
    def commands; self.class.commands; end

    # This method, when called in a class definition, creates a new
    # command for the device.  Commands are used for things that need
    # to be controlled directly, rather than by changing an associated
    # state. For example, a camera may have a "zoom in" and "zoom out"
    # feature but no command for setting the zoom level
    # directly. However, for situation where the command is changing
    # an obverable state, like with on/off, a state var should be used
    # instead. In addition to calling `command`, you should create a
    # method with the same name as the command--this will be called
    # when the command is activated by the user.  Alternatively, you
    # can pass in a proc to :action which will create this method
    # automatically.
    # @param [Symbol] name The name for the device. Should follow the
    #   general nameing convention: all lowercase, with multiple words
    #   connected\_by\_underscores.
    # @param [Hash] options Options for configuring the command
    # @option options [Symbol, Array<Symbol>] type The type of the
    #   argument. If only one argument, supply it directly; if
    #   multiple, supply an array of types. These types are used by
    #   the web interface to determine what kind of interface to
    #   display. Possible values are :boolean, :string, :percentage,
    #   :number, :decimal, and :option
    # @option options [Array<#to_json>] options If :option is selected
    #   for type, the elements in this array serve as the allowable
    #   options.
    # @option options [Proc] action If a proc is supplied to action,
    #   then `command` will automatically create a method with the
    #   same name as supplied; this method will be called whenever a
    #   user triggers the command, so it should communicate with the
    #   device and take the desired action.
    # @example
    #   command :zoom_in, :type => :percentage, :action => proc{|speed|
    #     send "zoom +#{speed}"
    #   }
    def self.command name, options = {}
      if options[:action].class == Proc
        define_method name, &options[:action]
      end
      @command_vars ||= {}
      @command_vars[name] = options
    end

    # Returns a string representation of the device
    # @return [String] A string representation of the device
    def inspect
      "<#{self.class.to_s}:0x#{object_id.to_s(16)}>"
    end

    # @return [Hash] A hash which, when converted to_json, is the
    #   CouchDB representation of the device. Includes all information
    #   neccessary to recreate the device on the next restart.
    def to_couch
      DaemonKit.logger.debug "Configuration: #{configuration}"
      hash = {:state_vars => {}, :config => configuration, :commands => {}}

      #if configuration
      # puts "Config vars: #{config_vars.inspect}"
      # config_vars.each{|var, options|
      #   hash[:config][var] = configuration[var]
      # }
      #end

      self.class.state_vars.each{|var, options|
        if options[:type] == :time
          options[:state] = eval("@#{var}.to_i")
        else
          options[:state] = eval("@#{var}")
        end
        hash[:state_vars][var] = options
      }
      if commands
        commands.each{|var, options| hash[:commands][var] = options}
      end

      return hash
    end

    # @param [Hash] hash A hash (probably created by {Device#to_couch}) which contains
    #   the information neccessary to recreate a device
    # @return [Device] A new Device instance created with all of the information
    #   in the hash passed in (which should have been created by {Device#to_couch}).
    def self.from_couch(hash)
      config = {}
      hash['attributes']['config'].each{|var, value|
        unless self.configuration[var.to_sym] && (@config_vars[var.to_sym] && !@config_vars[var.to_sym][:default])
          config[var] = value
        end
      } if hash['attributes']['config']
      device = self.new(config)
      device._id = hash['_id']
      device._rev = hash['_rev']
      device.belongs_to = hash['belongs_to']
      device.controller = hash['controller']
      state_vars = hash['attributes']['state_vars']
      state_vars ||= {}
      hash['attributes']['state_vars'] = nil
      hash['attributes']['command_vars'] = nil

      #merge the contents of the state_vars hash into attributes
      (hash['attributes'].merge(state_vars.each_key{|name|
        if state_vars[name]['kind'] == "time"
          begin
            state_vars[name] = Time.at(state_vars[name]['state'])
          rescue
          end
        else
          state_vars[name] = state_vars[name]['state']
        end
      })).each{|name, value|
        device.instance_variable_set("@#{name}", value)
      }
      return device
    end

    # @param [String] id The id of a CouchDB document for the device
    # @return [Device] A device instance created by downloading the specified CouchDB
    #   document and running {Device::from_couch} on it.
    def self.from_doc(id)
      from_couch(CouchRest.database(@database).get(id))
    end

    # Registers an error, which involves sending it as an event
    # @param [Symbol] name A symbol which uniquely identifies this
    #   error. Should be underscore-separated and should make sense in
    #   the context of an activity feed: for example,
    #   :projector_failed_to_turn_on, :printer_out_of_ink,
    #   :computer_unreachable
    # @param [String] description A longer description of the error,
    #   for example "Printer PACLab_4200 has only 3% of its black ink
    #   remaining."
    # @param [Float] severity A float between 0 and 1 which indicates
    #   the severity of the error. Normal events are given a severity
    #   of 0.1, so should probably be in excess of that if not
    #   completely routine.
    def register_error name, description, severity = 0.3
      message = {
        :error => true,
        :name => name,
        :description => description,
        :severity => severity
      }
      register_event message
    end

    # Sends an event to the event message queue
    # @param [Hash{Symbol, String => #to_json}] message The message to push onto 
    #   the event queue; can include a :severity key, which prioritizes the message
    #   in the web interface.
    def register_event message
      message[:device] = @_id
      message[:room] = @belongs_to
      message[:update] = true
      message[:severity] ||= 0.1
      message[:time] ||= Time.now.to_i
      @event_socket.send_msg(EVENT_TOPIC, message.to_json) if @event_socket
    end

    # Saves the current state of the device to CouchDB and sends updates on the update queue
    # if changed is passed in
    # @param [Symbol] changed The variable whose changing prompted this save
    # @param [#to_json] old_val The value of `changed` before it, well, changed
    def save changed = nil, old_val = nil
      retried = false
      begin
        hash = self.to_couch
        doc = {'attributes' => hash, 'class' => self.class, 'belongs_to' => @belongs_to, 'controller' => @controller, 'device' => true}
        if @_id && @_rev
          doc["_id"] = @_id
          doc["_rev"] = @_rev
        end
        @_rev = @db.save_doc(doc)['rev']
      rescue => e
        if !retried
          retried = true
          retry
        else
          DaemonKit.logger.exception e
        end
      end
      if changed
        update = {
          'state_update' => true,
          'var' => changed,
          'now' => self.instance_variable_get("@#{changed}")
        }
        update['was'] = old_val if old_val
        register_event update
      end
    end

    # @return [EventMachine::Deferrable] A deferrable which is
    #   notified when a state var changes. Look at the EventMachine
    #   documentation for more information about deferrables,
    def register_for_changes
      @change_deferrable ||= EM::DefaultDeferrable.new
      @change_deferrable
    end

    # Takes in a block which is specified as the callback for the
    # deferrable returned by {Device#register_for_changes}
    # automatically whenever a state var changes. Thus, the code in
    # the block will be run every time a change occurs, rather than
    # just once.
    def auto_register_for_changes(&block)
      @auto_register ||= []
      @auto_register << block
      register_for_changes.callback(&block)
    end
  end
end

# @private
class Object
  # @private
  # These methods dup all objects inside the hash/array as well as the
  # data structure itself However, because we don't check for cycles,
  # they will cause an infinite loop if present.
  def deep_dup
    begin
      if self.is_a? Symbol or self.is_a? TrueClass or self.is_a? FalseClass
        self
      else
        self.dup
      end
    rescue TypeError
      self
    end
  end
end

# @private
class Hash
  # @private
  # Converts all of the keys of a hash to symbols in place
  def symbolize_keys!
    t = self.dup
    self.clear
    t.each_pair{|k, v| self[k.to_sym] = v}
    self
  end
  # @private
  # @return [Hash] A copy of the hash with all keys converted to symbols
  def symbolize_keys
    t = {}
    self.each_pair{|k, v| t[k.to_sym] = v}
    t
  end
  # @private
  # These methods dup all objects inside the hash/array as well as the
  # data structure itself However, because we don't check for cycles,
  # they will cause an infinite loop if present.
  def deep_dup
    new_hash = {}
    self.each{|k, v| new_hash[k] = v.deep_dup}
    new_hash
  end
end

# @private
class Array
  # @private
  # These methods dup all objects inside the hash/array as well as the
  # data structure itself However, because we don't check for cycles,
  # they will cause an infinite loop if present.
  def deep_dup
    self.collect{|x| x.deep_dup}
  end
end
