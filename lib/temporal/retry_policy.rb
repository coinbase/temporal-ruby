require 'temporal/errors'

module Temporal
  class RetryPolicy < Struct.new(:initial_interval, :backoff_coefficient, :maximum_interval, :maximum_attempts,
    :non_retryable_error_types, keyword_init: true)

    class InvalidRetryPolicy < ClientError; end

    def validate!
      unless initial_interval
        raise InvalidRetryPolicy, 'initial_interval must be set'
      end

      unless [initial_interval, maximum_interval].compact.all? { |arg| arg.is_a?(Integer) }
        raise InvalidRetryPolicy, 'All intervals must be specified in whole seconds'
      end

      unless [initial_interval, maximum_interval].compact.all? { |arg| arg > 0 }
        raise InvalidRetryPolicy, 'All intervals must be greater than 0'
      end

      unless maximum_attempts.to_i >= 0
        raise InvalidRetryPolicy, 'maximum_attempts must be greater than or equal to 0'
      end
    end
  end
end
