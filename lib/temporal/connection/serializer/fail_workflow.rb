require 'temporal/connection/serializer/base'
require 'temporal/json'

module Temporal
  module Connection
    module Serializer
      class FailWorkflow < Base
        def to_proto
          Temporalio::Api::Command::V1::Command.new(
            command_type: Temporalio::Api::Enums::V1::CommandType::COMMAND_TYPE_FAIL_WORKFLOW_EXECUTION,
            fail_workflow_execution_command_attributes:
              Temporalio::Api::Command::V1::FailWorkflowExecutionCommandAttributes.new(
                failure: Failure.new(object.exception, converter).to_proto
              )
          )
        end
      end
    end
  end
end
