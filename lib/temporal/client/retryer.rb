module Temporal
  module Client
    module Retryer
      INITIAL_INTERVAL_S = 0.2
      MAX_INTERVAL_S = 6.0
      BACKOFF_COEFFICIENT = 1.2
      DEFAULT_RETRIES = 24 # gets us to about 60s given the other parameters, assuming 0 latency

      # Used for backoff retries in certain cases when calling temporal server.
      # on_retry - a proc that's executed each time you need to retry
      def self.with_retries(times: DEFAULT_RETRIES, on_retry: nil, &block)
        # Values taken from the Java SDK
        # https://github.com/temporalio/sdk-java/blob/ad8831d4a4d9d257baf3482ab49f1aa681895c0e/temporal-serviceclient/src/main/java/io/temporal/serviceclient/RpcRetryOptions.java#L32
        current_interval_s = INITIAL_INTERVAL_S
        retry_i = 0
        loop do
          begin
            return yield
          rescue
            raise if retry_i >= times
            retry_i += 1
            on_retry.call if on_retry
            sleep(current_interval_s)
            current_interval_s = [current_interval_s * BACKOFF_COEFFICIENT, MAX_INTERVAL_S].min
          end
        end
      end
    end
  end
end
