require "temporal/connection/serializer/base"

module Temporal
  module Connection
    module Serializer
      class ScheduleState < Base
        def to_proto
          return unless object

          Temporalio::Api::Schedule::V1::ScheduleState.new(
            notes: object.notes,
            paused: object.paused,
            limited_actions: object.limited_actions,
            remaining_actions: object.remaining_actions
          )
        end
      end
    end
  end
end
