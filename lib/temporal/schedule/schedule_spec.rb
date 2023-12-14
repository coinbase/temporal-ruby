module Temporal
  module Schedule
    # ScheduleSpec is a complete description of a set of absolute timestamps
    # (possibly infinite) that an action should occur at. The meaning of a
    # ScheduleSpec depends only on its contents and never changes, except that the
    # definition of a time zone can change over time (most commonly, when daylight
    # saving time policy changes for an area). To create a totally self-contained
    # ScheduleSpec, use UTC or include timezone_data

    # For input, you can provide zero or more of: calendars, intervals or
    # cron_expressions and all of them will be used (the schedule will take
    # action at the union of all of their times, minus the ones that match
    # exclude_structured_calendar).
    class ScheduleSpec
      # Calendar-based specifications of times.
      #
      # @return [Array<Temporal::Schedule::Calendar>]
      attr_reader :calendars

      # Interval-based specifications of times.
      #
      # @return [Array<Temporal::Schedule::Interval>]
      attr_reader :intervals

      # [Cron expressions](https://crontab.guru/). This is provided for easy
      # migration from legacy Cron Workflows. For new use cases, we recommend
      # using calendars or intervals for readability and maintainability.
      #
      #
      # The string can have 5, 6, or 7 fields, separated by spaces.
      #
      # - 5 fields:         minute, hour, day_of_month, month, day_of_week
      # - 6 fields:         minute, hour, day_of_month, month, day_of_week, year
      # - 7 fields: second, minute, hour, day_of_month, month, day_of_week, year
      #
      # Notes:
      #
      # - If year is not given, it defaults to *.
      # - If second is not given, it defaults to 0.
      # - Shorthands `@yearly`, `@monthly`, `@weekly`, `@daily`, and `@hourly` are also
      # accepted instead of the 5-7 time fields.
      # - `@every interval[/<phase>]` is accepted and gets compiled into an
      # IntervalSpec instead. `<interval>` and `<phase>` should be a decimal integer
      # with a unit suffix s, m, h, or d.
      # - Optionally, the string can be preceded by `CRON_TZ=<timezone name>` or
      # `TZ=<timezone name>`, which will get copied to {@link timezone}.
      # (In which case the {@link timezone} field should be left empty.)
      # - Optionally, "#" followed by a comment can appear at the end of the string.
      # - Note that the special case that some cron implementations have for
      # treating day_of_month and day_of_week as "or" instead of "and" when both
      # are set is not implemented.
      #
      # @return [Array<String>]
      attr_reader :cron_expressions

      # If set, any timestamps before start_time will be skipped.
      attr_reader :start_time

      # If set, any timestamps after end_time will be skipped.
      attr_reader :end_time

      # If set, the schedule will be randomly offset by up to this many seconds.
      attr_reader :jitter

      # Time zone to interpret all calendar-based specs in.
      #
      # If unset, defaults to UTC. We recommend using UTC for your application if
      # at all possible, to avoid various surprising properties of time zones.
      #
      # Time zones may be provided by name, corresponding to names in the IANA
      # time zone database (see https://www.iana.org/time-zones). The definition
      # will be loaded by the Temporal server from the environment it runs in.
      attr_reader :timezone_name

      # @param cron_expressions [Array<String>]
      # @param intervals [Array<Temporal::Schedule::Interval>]
      # @param calendars [Array<Temporal::Schedule::Calendar>]
      # @param start_time [Time] If set, any timestamps before start_time will be skipped.
      # @param end_time [Time] If set, any timestamps after end_time will be skipped.
      # @param jitter [Integer] If set, the schedule will be randomly offset by up to this many seconds.
      # @param timezone_name [String] If set, the schedule will be interpreted in this time zone.
      def initialize(cron_expressions: nil, intervals: nil, calendars: nil, start_time: nil, end_time: nil, jitter: nil, timezone_name: nil)
        @cron_expressions = cron_expressions || []
        @intervals = intervals || []
        @calendars = calendars || []
        @start_time = start_time
        @end_time = end_time
        @jitter = jitter
        @timezone_name = timezone_name
      end
    end
  end
end
