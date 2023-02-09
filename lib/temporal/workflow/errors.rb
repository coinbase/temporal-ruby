require 'temporal/errors'

module Temporal
  class Workflow
    class Errors
      extend Concerns::Payloads

      # Convert a failure returned from the server to an Error to raise to the client
      # failure: Temporal::Api::Failure::V1::Failure
      def self.generate_error(failure, default_exception_class = StandardError)
        case failure.failure_info
        when :application_failure_info

          error_type = failure.application_failure_info.type
          exception_class = safe_constantize(error_type)
          message = failure.message

          if exception_class.nil?
            Temporal.logger.error(
              'Could not find original error class. Defaulting to StandardError.',
              { original_error: error_type }
            )
            message = "#{error_type}: #{failure.message}"
            exception_class = default_exception_class
          end
          begin
            details = failure.application_failure_info.details
            exception_or_message = from_details_payloads(details)
            # v1 serialization only supports StandardErrors with a single "message" argument.
            # v2 serialization supports complex errors using our converters to serialize them.
            # enable v2 serialization in activities with Temporal.configuration.use_error_serialization_v2
            if exception_or_message.is_a?(Exception)
              exception = exception_or_message
            else
              exception = exception_class.new(message)
            end
          rescue StandardError => deserialization_error
            message = "#{exception_class}: #{message}"
            exception = default_exception_class.new(message)
            Temporal.logger.error(
              "Could not instantiate original error. Defaulting to StandardError. It's likely that your error's " \
              "initializer takes something more than just one positional argument. If so, make sure the worker running "\
              "your activities is setting Temporal.configuration.use_error_serialization_v2 to support this.",
              {
                original_error: error_type,
                serialized_error: details.payloads.first.data,
                instantiation_error_class: deserialization_error.class.to_s,
                instantiation_error_message: deserialization_error.message,
              },
            )
          end
          exception.tap do |exception|
            backtrace = failure.stack_trace.split("\n")
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

      WORKFLOW_ALREADY_EXISTS_SYM = Temporal::Api::Enums::V1::StartChildWorkflowExecutionFailedCause.lookup(
        Temporal::Api::Enums::V1::StartChildWorkflowExecutionFailedCause::START_CHILD_WORKFLOW_EXECUTION_FAILED_CAUSE_WORKFLOW_ALREADY_EXISTS
      )

      def self.generate_error_for_child_workflow_start(cause, workflow_id)
        if cause == WORKFLOW_ALREADY_EXISTS_SYM
          Temporal::WorkflowExecutionAlreadyStartedFailure.new(
            "The child workflow could not be started - per its workflow_id_reuse_policy, it conflicts with another workflow with the same id: #{workflow_id}",
          )
        else
          # Right now, there's only one cause, but temporal may add more in the future
          StandardError.new("The child workflow could not be started. Reason: #{cause}")
        end
      end

      private_class_method def self.safe_constantize(const)
        Object.const_get(const) if Object.const_defined?(const)
      rescue NameError
        nil
      end
    end
  end
end
