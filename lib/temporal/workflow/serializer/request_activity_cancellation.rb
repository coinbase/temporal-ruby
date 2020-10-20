require 'temporal/workflow/serializer/base'

module Temporal
  class Workflow
    module Serializer
      class RequestActivityCancellation < Base
        def to_proto
          Temporal::Api::Decision::V1::Command.new(
            command_type: Temporal::Api::Enums::V1::CommandType::COMMAND_TYPE_REQUEST_CANCEL_ACTIVITY_TASK,
            request_cancel_activity_task_command_attributes:
              Temporal::Api::Decision::V1::RequestCancelActivityTaskCommandAttributes.new(
                activity_id: object.activity_id.to_s
              )
          )
        end
      end
    end
  end
end
