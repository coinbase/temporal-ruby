require 'temporal/connection/serializer/base'
require 'temporal/concerns/payloads'

module Temporal
  module Connection
    module Serializer
      class CompleteWorkflow < Base
        include Concerns::Payloads

        def to_proto
          Temporalio::Api::Command::V1::Command.new(
            command_type: Temporalio::Api::Enums::V1::CommandType::COMMAND_TYPE_COMPLETE_WORKFLOW_EXECUTION,
            complete_workflow_execution_command_attributes:
              Temporalio::Api::Command::V1::CompleteWorkflowExecutionCommandAttributes.new(
                result: to_result_payloads(object.result)
              )
          )
        end
      end
    end
  end
end
