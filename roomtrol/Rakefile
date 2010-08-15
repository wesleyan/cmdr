$eventmachine_library = :pure_ruby
require 'eventmachine'
require File.dirname(__FILE__) + '/config/boot'

require 'rake'
require 'daemon_kit/tasks'

Dir[File.join(File.dirname(__FILE__), 'tasks/*.rake')].each { |rake| load rake }
