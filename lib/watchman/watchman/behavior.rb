class Behavior
  attr_reader :derived_from, :last_sampled
  
  def initialize(*params, &block)
    @sampling_method = block
    @last_sampled = Time.new
    @latest_value = 0
    @derived_from = params[:derived_from]
  end

  def modify_sampling(f)
    self.class.define_method :sample do
      result = sample
      f(sample)
    end
  end

  def sample
    @latest_value = @sampling_method.call
    @last_sampled = Time.new
  end
end
