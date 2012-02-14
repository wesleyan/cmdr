class ZMQClient
  attr_reader :received
  def subscribe &cb
    @cb = cb
  end
  
  def on_readable(socket, message)
    messages.each do |m|
      cb.call(m.copy_out_string) if cb
    end
  end
end
