require 'temporal/connection/serializer/base'
require 'temporal/concerns/payloads'

module Temporal
  module Connection
    module Serializer
      class SignalExternalWorkflow < Base
        include Concerns::Payloads

        def to_proto
          Temporal::Api::Command::V1::Command.new(
            command_type: Temporal::Api::Enums::V1::CommandType::COMMAND_TYPE_SIGNAL_EXTERNAL_WORKFLOW_EXECUTION,
            signal_external_workflow_execution_command_attributes:
              Temporal::Api::Command::V1::SignalExternalWorkflowExecutionCommandAttributes.new(
                namespace: object.namespace,
                execution: serialize_execution(object.execution),
                signal_name: object.signal_name,
                input: to_signal_payloads(object.input),
                control: "", # deprecated
                child_workflow_only: object.child_workflow_only
              )
          )
        end

        private

        def serialize_execution(execution)
          Temporal::Api::Common::V1::WorkflowExecution.new(workflow_id: execution[:workflow_id], run_id: execution[:run_id])
        end
      end
    end
  end
end
