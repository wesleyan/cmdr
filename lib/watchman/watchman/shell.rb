require 'net/http'

REPOSITORY = ''

class String
  def starts_with?(other)
    return self.index(other) == 0
  end
end

class Hash
  def combine(other)
    other.each do |k, v|
      if not self[k]
        self[k] = v
      end
    end
  end
end

class RemoteWatchman
  def connect
    
  end
  
  def method_missing(method, *args)
  end
end

class Shell
  def initialize
    @DEFAULTS = {
      :autocomplete => [],
      :edit_mode => false,
      :aliases => [],
      :assumes_connected => true,
      :make_sure => false
    }
    repl
  end

  def commands
    methods.find_all {|m| m.starts_with? "command_"}.collect do |match|
      m = match.split('_')[1].gsub '%20' ' '
    end
    
  end

  def self.command(name, *params, &code)
    define_method "command_#{name}", code
  end

  def execute(cmd, *args)
    send("command_#{cmd}", *args)
  end

  def get_input
    begin 
      gets.chomp 
    rescue
    end
  end
  
  def connect
    @connected = true
    @current_server = ''
  end

  def repl
    command = get_input
    if commands.include? command.split.first
      execute command
    elsif command.empty?
    else
      puts "Unknown command: #{command}"
    end
    repl
  end

  def get(what, *args)
    remote_call(:get, what, *args)
  end

  def post(what, *args)
    remote_call(:post, what, *args)
  end

  def remote_call(method, what, *args)
    if args[:server]
      server = args[:server]
    else
      server = @server
    end
    
    case method
    when :get
      res = Net:HTTP.get @current_server, what
    when :post
      res = Net:HTTP.post @current_server, what
    end

    case args[:return_as]
    when :list
      res.split ','
    when :success?
      res == 'true' ? true : false
    else
      res
    end
  end
end

class WatchmanShell < Shell
  command :connect, :autocomplete => [:watchmen], :assumes_connected => false do |serv|
    connect_to serv
  end

  command :disconnect, :assumes_connected => false do
    disconnect
  end

  command :watchmen do
    get '/list', :server => REPOSITORY
  end
  
  command :set_environment, :autocomplete => [:environments] do |env|
    post '/environment/set/#{env}'
  end

  command :environments, :aliases => [:list_environments] do
    get '/envionrment/list', :return_as => :list
  end

  command :interfaces, :aliases => [:list_interfaces] do |x|
    get '/interface/list', :return_as => :list
  end

  command :rules, :aliases => [:list_rules]  do 
    get '/environment/rules/list'
  end

  command :sample, :autocomplete => [:behaviors] do |behavior| 
    get '/behaviors/sample/#{behavior}', :return_as => :success?
  end
  
  command :create_behavior do |rule|
    post '/behaviors/create/#{rule}', :return_as => :success?
  end

  command :create_state, :edit_mode => true do |state|
    post '/states/create'
  end

  command :create_test, :edit_mode => true do |test|
    post '/environment/tests/add/#{test}'
  end

  command :add_rule, :edit_mode => true do |rule|
    post '/environment/rules/add/#{rule}', :return_as => :success?
  end

  command :delete_test, :autocomplete => [:tests], :make_sure => true do |test|
    post '/tests/delete/#{test}'
  end

  command :exit do
    exit
  end
end

WatchmanShell.new 


