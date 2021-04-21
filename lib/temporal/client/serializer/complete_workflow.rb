require 'temporal/client'

module Temporal
  module Client
    module Serializer
      class CompleteWorkflow < Base
        def to_proto
          Temporal::Api::Decision::V1::Command.new(
            command_type: Temporal::Api::Enums::V1::CommandType::COMMAND_TYPE_COMPLETE_WORKFLOW_EXECUTION,
            complete_workflow_execution_command_attributes:
              Temporal::Api::Decision::V1::CompleteWorkflowExecutionCommandAttributes.new(
                result: object.result.nil? ? nil : Temporal.configuration.converter.to_payloads([object.result])
              )
          )
        end
      end
    end
  end
end
