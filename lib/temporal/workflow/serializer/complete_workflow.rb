require 'temporal/workflow/serializer/base'
require 'temporal/workflow/serializer/payload'

module Temporal
  class Workflow
    module Serializer
      class CompleteWorkflow < Base
        def to_proto
          Temporal::Api::Decision::V1::Command.new(
            command_type: Temporal::Api::Enums::V1::CommandType::COMMAND_TYPE_COMPLETE_WORKFLOW_EXECUTION,
            complete_workflow_execution_command_attributes:
              Temporal::Api::Decision::V1::CompleteWorkflowExecutionCommandAttributes.new(
                result: Payload.new(object.result).to_proto
              )
          )
        end
      end
    end
  end
end
