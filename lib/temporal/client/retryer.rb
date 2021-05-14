module Temporal
  module Client
    module Retryer
      INITIAL_INTERVAL_S = 0.2
      MAX_INTERVAL_S = 6.0
      BACKOFF_COEFFICIENT = 1.2

      # Used for backoff retries in certain cases when calling temporal server.
      # metadata_hash: for logging, pass in metadata.to_h
      def self.retry_for(give_up_after_s, retry_message:, metadata_hash:, &block)
        # Values taken from the Java SDK
        # https://github.com/temporalio/sdk-java/blob/ad8831d4a4d9d257baf3482ab49f1aa681895c0e/temporal-serviceclient/src/main/java/io/temporal/serviceclient/RpcRetryOptions.java#L32
        current_interval_s = INITIAL_INTERVAL_S
        elapsed_s = 0.0
        result = nil
        loop do
          begin
            result = yield
          rescue
            Temporal.logger.debug(retry_message, metadata_hash)
            sleep(current_interval_s)
            elapsed_s += current_interval_s
            raise if elapsed_s >= give_up_after_s
            current_interval_s = [current_interval_s * BACKOFF_COEFFICIENT, MAX_INTERVAL_S].min
          else
            break
          end
        end
        result
      end
    end
  end
end
