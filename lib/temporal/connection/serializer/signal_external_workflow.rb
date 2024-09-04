require 'temporal/connection/serializer/base'

module Temporal
  module Connection
    module Serializer
      class SignalExternalWorkflow < Base
        def to_proto
          Temporalio::Api::Command::V1::Command.new(
            command_type: Temporalio::Api::Enums::V1::CommandType::COMMAND_TYPE_SIGNAL_EXTERNAL_WORKFLOW_EXECUTION,
            signal_external_workflow_execution_command_attributes:
              Temporalio::Api::Command::V1::SignalExternalWorkflowExecutionCommandAttributes.new(
                namespace: object.namespace,
                execution: serialize_execution(object.execution),
                signal_name: object.signal_name,
                input: converter.to_signal_payloads(object.input),
                control: "", # deprecated
                child_workflow_only: object.child_workflow_only
              )
          )
        end

        private

        def serialize_execution(execution)
          Temporalio::Api::Common::V1::WorkflowExecution.new(workflow_id: execution[:workflow_id], run_id: execution[:run_id])
        end
      end
    end
  end
end
