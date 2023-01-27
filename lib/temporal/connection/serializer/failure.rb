require 'temporal/connection/serializer/base'
require 'temporal/concerns/payloads'

module Temporal
  module Connection
    module Serializer
      class Failure < Base
        include Concerns::Payloads

        def initialize(error, serialize_whole_error: false)
          @serialize_whole_error = serialize_whole_error
          super(error)
        end

        def to_proto
          if @serialize_whole_error
            details_input = object
            type = "<SerializedError>"
          else
            details_input = object.message
            type = object.class.name
          end
          Temporal::Api::Failure::V1::Failure.new(
            message: object.message,
            stack_trace: stack_trace_from(object.backtrace),
            application_failure_info: Temporal::Api::Failure::V1::ApplicationFailureInfo.new(
              type: type,
              details: to_details_payloads(details_input)
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
