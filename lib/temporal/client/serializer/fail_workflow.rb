require 'temporal/client/serializer/base'
require 'temporal/json'

module Temporal
  module Client
    module Serializer
      class FailWorkflow < Base
        def to_proto
          Temporal::Api::Command::V1::Command.new(
            command_type: Temporal::Api::Enums::V1::CommandType::COMMAND_TYPE_FAIL_WORKFLOW_EXECUTION,
            fail_workflow_execution_command_attributes:
              Temporal::Api::Command::V1::FailWorkflowExecutionCommandAttributes.new(
                failure: Failure.new(object.exception).to_proto
              )
          )
        end
      end
    end
  end
end
