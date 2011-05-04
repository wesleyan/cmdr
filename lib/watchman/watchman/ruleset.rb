require 'set'
require 'ostruct'

class RuleSet
  def initialize(machine)
    @machine = machine
    @name = name
    @rules = []
    @computations = {}
  end

  def start
    while true
      
    end
  end

  def stop
    
  end

  def compute(b)
    @computations[b] = {
      :result => b.sample,
      :date => Time.now
    }
    return @computations[b]
  end

  def fork
    @name = "#{@name}-#{@machine}-#{Time.now}"
    #Repository.create_new @name @rules
  end

  def active_behaviors
    return @rules.collect {|r| r.behaviors}.flatten.uniq
  end

  def next_computations
    
  end
  
  def on
    @state
  end

  def off
    not on
  end

  def last_computed(b)
    return @computations[b]
  end

  def to_s
    @rules.collect { |r| r.to_s }
  end
end


