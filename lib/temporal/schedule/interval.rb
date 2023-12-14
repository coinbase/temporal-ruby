module Temporal
  module Schedule
    #  Interval matches times that can be expressed as:
    #  Epoch + (n * every) + offset
    #  where n is all integers ≥ 0.

    #  For example, an `every` of 1 hour with `offset` of zero would match
    #  every hour, on the hour. The same `every` but an `offset`
    #  of 19 minutes would match every `xx:19:00`. An `every` of 28 days with
    #  `offset` zero would match `2022-02-17T00:00:00Z` (among other times).
    #  The same `every` with `offset` of 3 days, 5 hours, and 23 minutes
    # would match `2022-02-20T05:23:00Z` instead.
    class Interval
      attr_reader :every, :offset

      # @param every [Integer] the number of seconds between each interval
      # @param offset [Integer] the number of seconds to provide as offset
      def initialize(every:, offset: nil)
        @every = every
        @offset = offset
      end
    end
  end
end
