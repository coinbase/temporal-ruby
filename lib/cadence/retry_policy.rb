require 'cadence/errors'

module Cadence
  class RetryPolicy < Struct.new(:interval, :backoff, :max_interval, :max_attempts,
    :expiration_interval, :non_retriable_errors, keyword_init: true)

    class InvalidRetryPolicy < ClientError; end

    def validate!
      unless interval && backoff
        raise InvalidRetryPolicy, 'interval and backoff must be set'
      end

      unless max_attempts || expiration_interval
        raise InvalidRetryPolicy, 'max_attempts or expiration_interval must be set'
      end

      unless [interval, max_interval, expiration_interval].compact.all? { |arg| arg.is_a?(Integer) }
        raise InvalidRetryPolicy, 'All intervals must be specified in whole seconds'
      end

      unless [interval, max_interval, expiration_interval].compact.all? { |arg| arg > 0 }
        raise InvalidRetryPolicy, 'All intervals must be greater than 0'
      end
    end
  end
end
