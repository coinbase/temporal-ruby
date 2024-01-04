module Temporal
  module Schedule

    # Calendar describes an event specification relative to the calendar,
    # similar to a traditional cron specification, but with labeled fields. Each
    # field can be one of:
    #   *: matches always
    #   x: matches when the field equals x
    #   x/y : matches when the field equals x+n*y where n is an integer
    #   x-z: matches when the field is between x and z inclusive
    #   w,x,y,...: matches when the field is one of the listed values
    #
    # Each x, y, z, ... is either a decimal integer, or a month or day of week name
    # or abbreviation (in the appropriate fields).
    #
    # A timestamp matches if all fields match.
    #
    # Note that fields have different default values, for convenience.
    #
    # Note that the special case that some cron implementations have for treating
    # day_of_month and day_of_week as "or" instead of "and" when both are set is
    # not implemented.
    #
    # day_of_week can accept 0 or 7 as Sunday
    class Calendar
      attr_reader :second, :minute, :hour, :day_of_month, :month, :year, :day_of_week, :comment

      # @param second [String] Expression to match seconds. Default: 0
      # @param minute [String] Expression to match minutes. Default: 0
      # @param hour [String] Expression to match hours. Default: 0
      # @param day_of_month [String] Expression to match days of the month. Default: *
      # @param month [String] Expression to match months. Default: *
      # @param year [String] Expression to match years. Default: *
      # @param day_of_week [String] Expression to match days of the week. Default: *
      # @param comment [String] Free form comment describing the intent of this calendar.
      def initialize(second: nil, minute: nil, hour: nil, day_of_month: nil, month: nil, year: nil, day_of_week: nil, comment: nil)
        @second = second
        @minute = minute
        @hour = hour
        @day_of_month = day_of_month
        @month = month
        @day_of_week = day_of_week
        @year = year
        @comment = comment
      end
    end
  end
end
