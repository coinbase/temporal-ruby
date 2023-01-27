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

          if failure.application_failure_info.type == 'Temporal::Activity::SerializedException'
            error_type, message = Temporal::Activity::SerializedExcepion.error_type_and_serialized_args(
              from_details_payloads(failure.application_failure_info.details)
            )
            user_provided_constructor = true
          else
            error_type = failure.application_failure_info.type
            message = from_details_payloads(failure.application_failure_info.details)
            user_provided_constructor = false
          end
          exception_class = safe_constantize(error_type)

          if exception_class.nil?
            Temporal.logger.error(
              'Could not find original error class. Defaulting to StandardError.',
              { original_error: error_type }
            )
            message = "#{error_type}: #{message}"
            exception_class = default_exception_class
          end
          begin
            exception = if user_provided_constructor
                          exception_class.from_serialized_args(message)
                        else
                          exception_class.new(message)
                        end
          rescue StandardError => deserialization_error
            message = "#{exception_class}: #{message}"
            exception = default_exception_class.new(message)
            Temporal.logger.error(
              'Could not instantiate original error. Defaulting to StandardError. You can avoid this by '\
              'raising an error that subclasses ActivityException, and which properly implements serialize '\
              'and from_serialized_args.',
              {
                original_error: error_type,
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
