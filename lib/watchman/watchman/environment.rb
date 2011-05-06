require 'watchman/behavior'
require 'watchman/state'

module Watchman
  class Environment
    def initialize
      @behaviors = []
      @states = []
      @interfaces = []
    end

    def add_behavior(&block)
      @behaviors.push(Behavior.new, &block)
    end

    def add_state(&block)
      @states.push(State.new, &block)
    end

    def add_interface(ifc)
      @interfaces.push(ifc)
    end

    def update
  #    `wget #{Watchman.ENVIRONMENT_URL}` 
    end
  end
end
