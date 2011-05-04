class Test
  def initialize
    @finished_steps = []
  end

  def self.step(name, params)
    @steps[name] = lambda {
      @active[name] = Thread.new {
        if params.keys.include?(:after)
          @active[params[:after]].join
        end

        @active[name] = false
      }
      @active[name].run
    }
  end
  
  def self.verify(what)
  end

  def check(name)
  end

  def done
    @active.none? {|x| x.status} 
  end
  
  def perform
    @steps.each { |_, f| f.call }
    until done
    end
    @active = []
    @conditions.all? { |cond| check(cond) }
  end
end

class SampleTest < Test
  step :open_pc
  step :open_projector, :after => :open_pc

  verify Projector.is_open
end
