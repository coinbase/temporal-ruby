require "temporal/connection/serializer/base"
require "temporal/connection/serializer/schedule_spec"
require "temporal/connection/serializer/schedule_action"
require "temporal/connection/serializer/schedule_policies"
require "temporal/connection/serializer/schedule_state"

module Temporal
  module Connection
    module Serializer
      class Schedule < Base
        def to_proto
          Temporalio::Api::Schedule::V1::Schedule.new(
            spec: Temporal::Connection::Serializer::ScheduleSpec.new(object.spec, converter).to_proto,
            action: Temporal::Connection::Serializer::ScheduleAction.new(object.action, converter).to_proto,
            policies: Temporal::Connection::Serializer::SchedulePolicies.new(object.policies, converter).to_proto,
            state: Temporal::Connection::Serializer::ScheduleState.new(object.state, converter).to_proto
          )
        end
      end
    end
  end
end
