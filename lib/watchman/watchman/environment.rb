class Environment
  def initialize
    @behaviors = []
    @states = []
  end

  def add_behavior(&block)
    @behaviors.push Behavior.new &block
  end

  def add_state(&block)
    @states.push State.new &block
  end

  def update
#    `wget #{Watchman.ENVIRONMENT_URL}` 
  end
end
