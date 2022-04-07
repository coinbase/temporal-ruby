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
          message = from_details_payloads(failure.application_failure_info.details)

          exception_class = safe_constantize(failure.application_failure_info.type)
          if exception_class.nil?
            Temporal.logger.error(
              "Could not find original error class. Defaulting to StandardError.", 
              {original_error: failure.application_failure_info.type},
            )
            message = "#{failure.application_failure_info.type}: #{message}"
            exception_class = default_exception_class
          end


          begin
            exception = exception_class.new(message)
          rescue => deserialization_error
            # We don't currently support serializing/deserializing exceptions with more than one argument.
            message = "#{exception_class}: #{message}"
            exception = default_exception_class.new(message)
            Temporal.logger.error(
              "Could not instantiate original error. Defaulting to StandardError.", 
              {
                original_error: failure.application_failure_info.type,
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
