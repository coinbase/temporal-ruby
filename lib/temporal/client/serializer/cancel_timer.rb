require 'temporal/client/serializer/base'

module Temporal
  module Client
    module Serializer
      class CancelTimer < Base
        def to_proto
          Temporal::Api::Command::V1::Command.new(
            command_type: Temporal::Api::Enums::V1::CommandType::COMMAND_TYPE_CANCEL_TIMER,
            cancel_timer_command_attributes:
              Temporal::Api::Command::V1::CancelTimerCommandAttributes.new(
                timer_id: object.timer_id.to_s
              )
          )
        end
      end
    end
  end
end
