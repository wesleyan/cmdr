class ZMQClient
  def subscribe &cb
    @cb = cb
  end

  def subscribe_multi &cb
    @cb = cb
    @multi = true
  end

  def on_readable(socket, messages)
    if @multi
      @cb.call(socket, messages.map(&:copy_out_string)) if @cb
    else
      messages.each do |m|
        @cb.call(m.copy_out_string) if @cb
      end
    end
  end
end
