require 'temporal/client/serializer/base'

module Temporal
  module Client
    module Serializer
      class StartTimer < Base
        def to_proto
          Temporal::Api::Command::V1::Command.new(
            command_type: Temporal::Api::Enums::V1::CommandType::COMMAND_TYPE_START_TIMER,
            start_timer_command_attributes:
              Temporal::Api::Command::V1::StartTimerCommandAttributes.new(
                timer_id: object.timer_id.to_s,
                start_to_fire_timeout: object.timeout
              )
          )
        end
      end
    end
  end
end
