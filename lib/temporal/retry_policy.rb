require 'temporal/errors'

module Temporal
  # See https://docs.temporal.io/docs/go/retries/ for go documentation of equivalent concepts.
  class RetryPolicy < Struct.new(:interval, :backoff, :max_interval, :max_attempts,
    :non_retriable_errors, keyword_init: true)

    class InvalidRetryPolicy < ClientError; end

    def validate!
      unless max_attempts == 1 || (interval && backoff)
        raise InvalidRetryPolicy, 'interval and backoff must be set if max_attempts != 1'
      end

      unless [interval, max_interval].compact.all? { |arg| arg.is_a?(Integer) }
        raise InvalidRetryPolicy, 'All intervals must be specified in whole seconds'
      end

      unless [interval, max_interval].compact.all? { |arg| arg > 0 }
        raise InvalidRetryPolicy, 'All intervals must be greater than 0'
      end
    end
  end
end
