class State
  def initialize(callback, &block)
    @check_func = block
    @callback = callback
    start
  end

  def start
    @thread = Thread.new do
      while true
        if @check_func
          switch true
        else
          switch nil
        end
      end
    end
    @thread.start
  end

  def stop
    @thread.kill
  end

  def on
    @state
  end

  def off
    not @state
  end

  def switch(s)
    if s
      if off 
        @state = nil
        @callback
      end
    else
      if on
        @state = true
        @callback
      end
    end
  end
end
