class Interface
  def self.behavior(name, &block)
    @behaviors[name.to_s] = new Behavior(block)
  end

  def self.state(name, &block)
    transformed = lambda {
      r = block.call
      !!r and r != ''
    }
    @states[name.to_s] = new State(transformed)
  end

  def self.parameter(vars)
    define_method :initialize do |params|
      for variable in vars
        if params[variable]
          self.class.instance_variable_set(variable, params[variable])
        end
      end
    end
  end

  def method_missing(method, *args)
    case method.to_s
    when /is_(.*)?/;
      self.class.instance_variable_get(method.to_s.split('_')[1].split('?')[0]).state
    end
  end
end

class UnixProcess < Interface
  parameter :pid

  state :up do
    `ps -eo pid | grep #{@pid}` 
  end

  behavior :cpu_usage  do
    `ps -eo pid,pcu | grep #{@pid}`
  end

  behavior :memory_usage do
    `ps -eo pid,pmem | grep #{@pid}`
  end
end

class System < Interface 
  behavior :load_average do
    `uptime | awk '{print $10}' | cut -d, -f1`
  end

  behavior :disk_usage do
    `df -P | grep -i /dev/sda1 | awk '{print $5}' | sed 's/%//'`	
  end
end
  
class Network < Interface
  parameter :interface
  
  state :up do
    `ifconfig #{@interface} | grep 'inet addr'`
  end

  behavior :out_traffic do
    `ifstat -i eth1 0.1 1 | tail -n1 | awk '{ print $2 }'`
  end

  behavior :in_traffic do
    `ifstat -i eth1 0.1 1 | tail -n1 | awk '{ print $1 }'`
  end
end

