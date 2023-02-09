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
          details = if @serialize_whole_error
                      to_details_payloads(object)
                    else
                      to_details_payloads(object.message)
                    end
          Temporal::Api::Failure::V1::Failure.new(
            message: object.message,
            stack_trace: stack_trace_from(object.backtrace),
            application_failure_info: Temporal::Api::Failure::V1::ApplicationFailureInfo.new(
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
