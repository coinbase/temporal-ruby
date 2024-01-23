require 'temporal/connection/serializer/base'

module Temporal
  module Connection
    module Serializer
      class Failure < Base

        def initialize(error, serialize_whole_error: false, max_bytes: 200_000)
          @serialize_whole_error = serialize_whole_error
          @max_bytes = max_bytes
          super(error)
        end

        def to_proto
          if @serialize_whole_error
            details = converter.to_details_payloads(object)
            if details.payloads.first.data.size > @max_bytes
              Temporal.logger.error(
                "Could not serialize exception because it's too large, so we are using a fallback that may not "\
                  "deserialize correctly on the client.  First #{@max_bytes} bytes:\n" \
                "#{details.payloads.first.data[0..@max_bytes - 1]}",
                {unserializable_error: object.class.name}
              )
              # Fallback to a more conservative serialization if the payload is too big to avoid
              # sending a huge amount of data to temporal and putting it in the history.
              details = converter.to_details_payloads(object.message)
            end
          else
            details = converter.to_details_payloads(object.message)
          end
          Temporalio::Api::Failure::V1::Failure.new(
            message: object.message,
            stack_trace: stack_trace_from(object.backtrace),
            application_failure_info: Temporalio::Api::Failure::V1::ApplicationFailureInfo.new(
              type: object.class.name,
              details: details
            )
          )
        end

        private

        def stack_trace_from(backtrace)
          return unless backtrace

          backtrace.join("\n")
        end
      end
    end
  end
end
