require 'temporal/connection/serializer/base'

module Temporal
  module Connection
    module Serializer
      class CancelTimer < Base
        def to_proto
          Temporalio::Api::Command::V1::Command.new(
            command_type: Temporalio::Api::Enums::V1::CommandType::COMMAND_TYPE_CANCEL_TIMER,
            cancel_timer_command_attributes:
              Temporalio::Api::Command::V1::CancelTimerCommandAttributes.new(
                timer_id: object.timer_id.to_s
              )
          )
        end
      end
    end
  end
end
