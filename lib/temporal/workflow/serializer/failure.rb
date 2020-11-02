require 'temporal/workflow/serializer/base'
require 'temporal/json'

module Temporal
  class Workflow
    module Serializer
      class Failure < Base
        def to_proto
          Temporal::Api::Failure::V1::Failure.new(
            message: object.message,
            stack_trace: stack_trace_from(object.backtrace),
            application_failure_info: Temporal::Api::Failure::V1::ApplicationFailureInfo.new(
              type: object.class.name,
              details: Payload.new(object.message).to_proto
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
