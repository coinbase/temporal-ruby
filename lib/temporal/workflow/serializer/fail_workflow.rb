require 'temporal/workflow/serializer/base'
require 'temporal/json'

module Temporal
  class Workflow
    module Serializer
      class FailWorkflow < Base
        def to_proto
          Temporal::Api::Decision::V1::Command.new(
            command_type: Temporal::Api::Enums::V1::CommandType::COMMAND_TYPE_FAIL_WORKFLOW_EXECUTION,
            fail_workflow_execution_command_attributes:
              Temporal::Api::Decision::V1::FailWorkflowExecutionCommandAttributes.new(
                failure: Temporal::Api::Failure::V1::Failure.new(message: object.reason)
                # reason: object.reason,
                # details: JSON.serialize(object.details)
              )
          )
        end
      end
    end
  end
end
