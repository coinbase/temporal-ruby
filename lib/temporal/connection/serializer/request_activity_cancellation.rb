require 'temporal/connection/serializer/base'

module Temporal
  module Connection
    module Serializer
      class RequestActivityCancellation < Base
        def to_proto
          Temporalio::Api::Command::V1::Command.new(
            command_type: Temporalio::Api::Enums::V1::CommandType::COMMAND_TYPE_REQUEST_CANCEL_ACTIVITY_TASK,
            request_cancel_activity_task_command_attributes:
              Temporalio::Api::Command::V1::RequestCancelActivityTaskCommandAttributes.new(
                scheduled_event_id: object.activity_id.to_i
              )
          )
        end
      end
    end
  end
end
