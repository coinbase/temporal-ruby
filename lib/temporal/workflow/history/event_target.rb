require 'temporal/errors'

module Temporal
  class Workflow
    class History
      class EventTarget
        class UnexpectedEventType < InternalError; end

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

        TARGET_TYPES = {
          'ACTIVITY_TASK'                              => ACTIVITY_TYPE,
          'ACTIVITY_TASK_CANCEL'                       => CANCEL_ACTIVITY_REQUEST_TYPE,
          'REQUEST_CANCEL_ACTIVITY_TASK'               => CANCEL_ACTIVITY_REQUEST_TYPE,
          'TIMER'                                      => TIMER_TYPE,
          'CANCEL_TIMER'                               => CANCEL_TIMER_REQUEST_TYPE,
          'CHILD_WORKFLOW_EXECUTION'                   => CHILD_WORKFLOW_TYPE,
          'START_CHILD_WORKFLOW_EXECUTION'             => CHILD_WORKFLOW_TYPE,
          'MARKER'                                     => MARKER_TYPE,
          'EXTERNAL_WORKFLOW_EXECUTION'                => EXTERNAL_WORKFLOW_TYPE,
          'SIGNAL_EXTERNAL_WORKFLOW_EXECUTION'         => EXTERNAL_WORKFLOW_TYPE,
          'EXTERNAL_WORKFLOW_EXECUTION_CANCEL'         => CANCEL_EXTERNAL_WORKFLOW_REQUEST_TYPE,
          'REQUEST_CANCEL_EXTERNAL_WORKFLOW_EXECUTION' => CANCEL_EXTERNAL_WORKFLOW_REQUEST_TYPE,
          'UPSERT_WORKFLOW_SEARCH_ATTRIBUTES'          => WORKFLOW_TYPE,
          'WORKFLOW_EXECUTION'                         => WORKFLOW_TYPE,
          'WORKFLOW_EXECUTION_CANCEL'                  => CANCEL_WORKFLOW_REQUEST_TYPE,
        }.freeze

        attr_reader :id, :type

        def self.workflow
          @workflow ||= new(1, WORKFLOW_TYPE)
        end

        def self.from_event(event)
          _, target_type = TARGET_TYPES.find { |type, _| event.type.start_with?(type) }

          unless target_type
            raise UnexpectedEventType, "Unexpected event #{event.type}"
          end

          new(event.originating_event_id, target_type)
        end

        def initialize(id, type)
          @id = id
          @type = type

          freeze
        end

        def ==(other)
          id == other.id && type == other.type
        end

        def eql?(other)
          self == other
        end

        def hash
          [id, type].hash
        end

        def to_s
          "#{type} (#{id})"
        end
      end
    end
  end
end
