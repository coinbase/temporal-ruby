require 'temporal/errors'

module Temporal
  class Workflow
    class History
      class EventTarget
        class UnexpectedEventType < InternalError; end
        class UnexpectedDecisionType < InternalError; end

        ACTIVITY_TYPE                         = :activity
        CANCEL_ACTIVITY_REQUEST_TYPE          = :cancel_activity_request
        TIMER_TYPE                            = :timer
        CANCEL_TIMER_REQUEST_TYPE             = :cancel_timer_request
        CHILD_WORKFLOW_TYPE                   = :child_workflow
        MARKER_TYPE                           = :marker
        EXTERNAL_WORKFLOW_TYPE                = :external_workflow
        CANCEL_EXTERNAL_WORKFLOW_REQUEST_TYPE = :cancel_external_workflow_request
        WORKFLOW_TYPE                         = :workflow
        CANCEL_WORKFLOW_REQUEST_TYPE          = :cancel_workflow_request
        UPSERT_SEARCH_ATTRIBUTES_REQUEST_TYPE = :upsert_search_attributes_request

        # NOTE: The order is important, first prefix match wins (will be a longer match)
        EVENT_TARGET_TYPES = {
          'ACTIVITY_TASK_CANCEL_REQUESTED'             => CANCEL_ACTIVITY_REQUEST_TYPE,
          'ACTIVITY_TASK'                              => ACTIVITY_TYPE,
          'REQUEST_CANCEL_ACTIVITY_TASK'               => CANCEL_ACTIVITY_REQUEST_TYPE,
          'TIMER_CANCELED'                             => CANCEL_TIMER_REQUEST_TYPE,
          'TIMER'                                      => TIMER_TYPE,
          'CANCEL_TIMER'                               => CANCEL_TIMER_REQUEST_TYPE,
          'CHILD_WORKFLOW_EXECUTION'                   => CHILD_WORKFLOW_TYPE,
          'START_CHILD_WORKFLOW_EXECUTION'             => CHILD_WORKFLOW_TYPE,
          'MARKER'                                     => MARKER_TYPE,
          'EXTERNAL_WORKFLOW_EXECUTION'                => EXTERNAL_WORKFLOW_TYPE,
          'SIGNAL_EXTERNAL_WORKFLOW_EXECUTION'         => EXTERNAL_WORKFLOW_TYPE,
          'EXTERNAL_WORKFLOW_EXECUTION_CANCEL'         => CANCEL_EXTERNAL_WORKFLOW_REQUEST_TYPE,
          'REQUEST_CANCEL_EXTERNAL_WORKFLOW_EXECUTION' => CANCEL_EXTERNAL_WORKFLOW_REQUEST_TYPE,
          'UPSERT_WORKFLOW_SEARCH_ATTRIBUTES'          => UPSERT_SEARCH_ATTRIBUTES_REQUEST_TYPE,
          'WORKFLOW_EXECUTION_CANCEL'                  => CANCEL_WORKFLOW_REQUEST_TYPE,
          'WORKFLOW_EXECUTION'                         => WORKFLOW_TYPE,
        }.freeze

        DECISION_TARGET_TYPES = {
          'Cadence::Workflow::Decision::ScheduleActivity'            => ACTIVITY_TYPE,
          'Cadence::Workflow::Decision::RequestActivityCancellation' => CANCEL_ACTIVITY_REQUEST_TYPE,
          'Cadence::Workflow::Decision::RecordMarker'                => MARKER_TYPE,
          'Cadence::Workflow::Decision::StartTimer'                  => TIMER_TYPE,
          'Cadence::Workflow::Decision::CancelTimer'                 => CANCEL_TIMER_REQUEST_TYPE,
          'Cadence::Workflow::Decision::CompleteWorkflow'            => WORKFLOW_TYPE,
          'Cadence::Workflow::Decision::FailWorkflow'                => WORKFLOW_TYPE,
          'Cadence::Workflow::Decision::StartChildWorkflow'          => CHILD_WORKFLOW_TYPE,
        }.freeze

        DECISION_ATTRIBUTE_LISTS = {
          'Cadence::Workflow::Decision::ScheduleActivity'            => [:activity_id, :activity_type, :input],
        }

        attr_reader :id, :type, :attributes

        def self.workflow
          @workflow ||= new(1, WORKFLOW_TYPE)
        end

        def self.from_event(event)
          _, target_type = EVENT_TARGET_TYPES.find { |type, _| event.type.start_with?(type) }

          unless target_type
            raise UnexpectedEventType, "Unexpected event #{event.type}"
          end

          new(event.decision_id, target_type, attributes: event.target_attributes)
        end

        def self.from_decision(decision_id, decision)
          decision_type = decision.class.name
          target_type = DECISION_TARGET_TYPES[decision_type]

          unless target_type
            raise UnexpectedDecisionType, "Unexpected decision type #{decision_type}"
          end

          attribute_list = DECISION_ATTRIBUTE_LISTS.fetch(decision_type, [])

          new(decision_id, target_type, attributes: decision.to_h.slice(*attribute_list))
        end

        def initialize(id, type, attributes: {})
          @id = id
          @type = type
          @attributes = attributes

          freeze
        end

        def ==(other)
          self.class == other.class && id == other.id && type == other.type
        end

        def eql?(other)
          self == other
        end

        def hash
          [id, type].hash
        end

        def to_s
          "#{type}: #{id} (#{attributes})"
        end
      end
    end
  end
end
