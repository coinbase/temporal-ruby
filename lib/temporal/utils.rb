module Temporal
  module Utils
    NANO = 10**9
    MILLI = 10**3

    class << self
      def time_from_nanos(timestamp)
        seconds, nanoseconds = timestamp.divmod(NANO)
        Time.at(seconds, nanoseconds, :nsec)
      end

      def time_to_nanos(time)
        time.to_f * NANO
      end
    end
  end
end
