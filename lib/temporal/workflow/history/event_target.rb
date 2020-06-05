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
          'ActivityTask'                           => ACTIVITY_TYPE,
          'ActivityTaskCancel'                     => CANCEL_ACTIVITY_REQUEST_TYPE,
          'RequestCancelActivityTask'              => CANCEL_ACTIVITY_REQUEST_TYPE,
          'Timer'                                  => TIMER_TYPE,
          'CancelTimer'                            => CANCEL_TIMER_REQUEST_TYPE,
          'ChildWorkflowExecution'                 => CHILD_WORKFLOW_TYPE,
          'StartChildWorkflowExecution'            => CHILD_WORKFLOW_TYPE,
          'Marker'                                 => MARKER_TYPE,
          'ExternalWorkflowExecution'              => EXTERNAL_WORKFLOW_TYPE,
          'SignalExternalWorkflowExecution'        => EXTERNAL_WORKFLOW_TYPE,
          'ExternalWorkflowExecutionCancel'        => CANCEL_EXTERNAL_WORKFLOW_REQUEST_TYPE,
          'RequestCancelExternalWorkflowExecution' => CANCEL_EXTERNAL_WORKFLOW_REQUEST_TYPE,
          'UpsertWorkflowSearchAttributes'         => WORKFLOW_TYPE,
          'WorkflowExecution'                      => WORKFLOW_TYPE,
          'WorkflowExecutionCancel'                => CANCEL_WORKFLOW_REQUEST_TYPE,
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

          new(event.decision_id, target_type)
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
      end
    end
  end
end
