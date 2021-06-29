module Temporal
  class Workflow
    class Errors
      include Concerns::Payloads

      # Convert a failure returned from the server to an Error to raise to the client
      # failure: Temporal::Api::Failure::V1::Failure
      def error_from(failure, default_exception_class = StandardError)
        case failure.failure_info
        when :application_failure_info
          exception_class = safe_constantize(failure.application_failure_info.type)
          exception_class ||= default_exception_class
          message = from_details_payloads(failure.application_failure_info.details)
          backtrace = failure.stack_trace.split("\n")

          exception_class.new(message).tap do |exception|
            exception.set_backtrace(backtrace) if !backtrace.empty?
          end
        when :timeout_failure_info
          TimeoutError.new("Timeout type: #{failure.timeout_failure_info.timeout_type.to_s}")
        when :canceled_failure_info
          # TODO: Distinguish between different entity cancellations
          StandardError.new(from_payloads(failure.canceled_failure_info.details))
        else
          StandardError.new(failure.message)
        end
      end

      private

      def safe_constantize(const)
        Object.const_get(const) if Object.const_defined?(const)
      rescue NameError
        nil
      end



    end
  end
end
