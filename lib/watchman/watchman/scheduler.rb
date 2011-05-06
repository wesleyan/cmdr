module Watchman
  class Scheduler
    def schedule(room)
      hours = (1..12).collect(get_slot)
    end

    def get_slot(time)
      "#{time.hour}-#{time.hour + 1}"
    end

    def open_at?(time)
      #slot = 
      slot = time.hour
      !!@events[slot]
    end

    def open_now?
      open_at?(Time.now)
    end

    def event_at?(time)
      slot = time.hour
      @events[slot]
    end

    def event_now?
      event_at?(Time.now)
    end
  end
end

