require 'temporal/connection/serializer/base'

module Temporal
  module Connection
    module Serializer
      class Failure < Base
        def to_proto
          Temporal::Api::Failure::V1::Failure.new(
            message: object.message,
            stack_trace: stack_trace_from(object.backtrace),
            application_failure_info: Temporal::Api::Failure::V1::ApplicationFailureInfo.new(
              type: object.class.name,
              details: converter.to_details_payloads(object.message)
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
