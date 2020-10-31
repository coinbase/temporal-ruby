require 'temporal/json'
require 'temporal/errors'
require 'temporal/workflow/workflow_task'
require 'temporal/workflow/workflow_task_state_machine'
require 'temporal/workflow/history/event_target'
require 'temporal/metadata'

module Temporal
  class Workflow
    class StateManager
      SIDE_EFFECT_MARKER = 'SIDE_EFFECT'.freeze
      RELEASE_MARKER = 'RELEASE'.freeze

      class UnsupportedEvent < Temporal::InternalError; end
      class UnsupportedMarkerType < Temporal::InternalError; end

      attr_reader :workflow_tasks, :local_time

      def initialize(dispatcher)
        @dispatcher = dispatcher
        @workflow_tasks = []
        @marker_ids = Set.new
        @releases = {}
        @side_effects = []
        @workflow_task_tracker = Hash.new { |hash, key| hash[key] = WorkflowTaskStateMachine.new }
        @last_event_id = 0
        @local_time = nil
        @replay = false
      end

      def replay?
        @replay
      end

      def schedule(workflow_task)
        # Fast-forward event IDs to skip all the markers (version markers can
        # be removed, so we can't rely on them being scheduled during a replay)
        workflow_task_id = next_event_id
        while marker_ids.include?(workflow_task_id) do
          workflow_task_id = next_event_id
        end

        cancelation_id =
          case workflow_task
          when WorkflowTask::ScheduleActivity
            workflow_task.activity_id ||= workflow_task_id
          when WorkflowTask::StartChildWorkflow
            workflow_task.workflow_id ||= workflow_task_id
          when WorkflowTask::StartTimer
            workflow_task.timer_id ||= workflow_task_id
          end

        state_machine = workflow_task_tracker[workflow_task_id]
        state_machine.requested if state_machine.state == WorkflowTaskStateMachine::NEW_STATE

        workflow_tasks << [workflow_task_id, workflow_task]

        return [event_target_from(workflow_task_id, workflow_task), cancelation_id]
      end

      def release?(release_name)
        track_release(release_name) unless releases.key?(release_name)

        releases[release_name]
      end

      def next_side_effect
        side_effects.shift
      end

      def apply(history_window)
        @replay = history_window.replay?
        @local_time = history_window.local_time
        @last_event_id = history_window.last_event_id

        # handle markers first since their data is needed for processing events
        history_window.markers.each do |event|
          apply_event(event)
        end

        history_window.events.each do |event|
          apply_event(event)
        end
      end

      private

      attr_reader :dispatcher, :workflow_task_tracker, :marker_ids, :side_effects, :releases

      def next_event_id
        @last_event_id += 1
      end

      def apply_event(event)
        state_machine = workflow_task_tracker[event.workflow_task_id]
        target = History::EventTarget.from_event(event)

        case event.type
        when 'WORKFLOW_EXECUTION_STARTED'
          state_machine.start
          dispatch(
            History::EventTarget.workflow,
            'started',
            safe_parse(event.attributes.input),
            Metadata.generate(Metadata::WORKFLOW_TYPE, event.attributes)
          )

        when 'WORKFLOW_EXECUTION_COMPLETED'
          # todo

        when 'WORKFLOW_EXECUTION_FAILED'
          # todo

        when 'WORKFLOW_EXECUTION_TIMED_OUT'
          # todo

        when 'WORKFLOW_TASK_SCHEDULED'
          # todo

        when 'WORKFLOW_TASK_STARTED'
          # todo

        when 'WORKFLOW_TASK_COMPLETED'
          # todo

        when 'WORKFLOW_TASK_TIMED_OUT'
          # todo

        when 'WORKFLOW_TASK_FAILED'
          # todo

        when 'ACTIVITY_TASK_SCHEDULED'
          state_machine.schedule
          discard_workflow_task(event.workflow_task_id)

        when 'ACTIVITY_TASK_STARTED'
          state_machine.start

        when 'ACTIVITY_TASK_COMPLETED'
          state_machine.complete
          dispatch(target, 'completed', safe_parse(event.attributes.result))

        when 'ACTIVITY_TASK_FAILED'
          state_machine.fail
          dispatch(target, 'failed', event.attributes.reason, safe_parse(event.attributes.details))

        when 'ACTIVITY_TASK_TIMED_OUT'
          state_machine.time_out
          type = event.attributes.timeout_type.to_s
          dispatch(target, 'failed', 'Temporal::TimeoutError', "Timeout type: #{type}")

        when 'ACTIVITY_TASK_CANCEL_REQUESTED'
          state_machine.requested
          discard_workflow_task(event.workflow_task_id)

        when 'REQUEST_CANCEL_ACTIVITY_TASK_FAILED'
          state_machine.fail
          dispatch(target, 'failed', event.attributes.cause, nil)

        when 'ACTIVITY_TASK_CANCELED'
          state_machine.cancel
          dispatch(target, 'failed', 'CANCELLED', safe_parse(event.attributes.details))

        when 'TIMER_STARTED'
          state_machine.start
          discard_workflow_task(event.workflow_task_id)

        when 'TIMER_FIRED'
          state_machine.complete
          dispatch(target, 'fired')

        when 'CANCEL_TIMER_FAILED'
          state_machine.failed
          dispatch(target, 'failed', event.attributes.cause, nil)

        when 'TIMER_CANCELED'
          state_machine.cancel
          dispatch(target, 'canceled')

        when 'WORKFLOW_EXECUTION_CANCEL_REQUESTED'
          # todo

        when 'WORKFLOW_EXECUTION_CANCELED'
          # todo

        when 'REQUEST_CANCEL_EXTERNAL_WORKFLOW_EXECUTION_INITIATED'
          # todo

        when 'REQUEST_CANCEL_EXTERNAL_WORKFLOW_EXECUTION_FAILED'
          # todo

        when 'EXTERNAL_WORKFLOW_EXECUTION_CANCEL_REQUESTED'
          # todo

        when 'MARKER_RECORDED'
          state_machine.complete
          handle_marker(event.id, event.attributes.marker_name, safe_parse(event.attributes.details[:data]))

        when 'WORKFLOW_EXECUTION_SIGNALED'
          dispatch(target, 'signaled', event.attributes.signal_name, safe_parse(event.attributes.input))

        when 'WORKFLOW_EXECUTION_TERMINATED'
          # todo

        when 'WORKFLOW_EXECUTION_CONTINUED_AS_NEW'
          # todo

        when 'START_CHILD_WORKFLOW_EXECUTION_INITIATED'
          state_machine.schedule
          discard_workflow_task(event.workflow_task_id)

        when 'START_CHILD_WORKFLOW_EXECUTION_FAILED'
          state_machine.fail
          dispatch(target, 'failed', 'StandardError', safe_parse(event.attributes.cause))

        when 'CHILD_WORKFLOW_EXECUTION_STARTED'
          state_machine.start

        when 'CHILD_WORKFLOW_EXECUTION_COMPLETED'
          state_machine.complete
          dispatch(target, 'completed', safe_parse(event.attributes.result))

        when 'CHILD_WORKFLOW_EXECUTION_FAILED'
          state_machine.fail
          dispatch(target, 'failed', event.attributes.reason, safe_parse(event.attributes.details))

        when 'CHILD_WORKFLOW_EXECUTION_CANCELED'
          state_machine.cancel
          dispatch(target, 'failed', 'CANCELLED', safe_parse(event.attributes.details))

        when 'CHILD_WORKFLOW_EXECUTION_TIMED_OUT'
          state_machine.time_out
          type = event.attributes.timeoutType.to_s
          dispatch(target, 'failed', 'Temporal::TimeoutError', "Timeout type: #{type}")

        when 'CHILD_WORKFLOW_EXECUTION_TERMINATED'
          # todo

        when 'SIGNAL_EXTERNAL_WORKFLOW_EXECUTION_INITIATED'
          # todo

        when 'SIGNAL_EXTERNAL_WORKFLOW_EXECUTION_FAILED'
          # todo

        when 'EXTERNAL_WORKFLOW_EXECUTION_SIGNALED'
          # todo

        when 'UPSERT_WORKFLOW_SEARCH_ATTRIBUTES'
          # todo

        else
          raise UnsupportedEvent, event.type
        end
      end

      def event_target_from(workflow_task_id, workflow_task)
        target_type =
          case workflow_task
          when WorkflowTask::ScheduleActivity
            History::EventTarget::ACTIVITY_TYPE
          when WorkflowTask::RequestActivityCancellation
            History::EventTarget::CANCEL_ACTIVITY_REQUEST_TYPE
          when WorkflowTask::RecordMarker
            History::EventTarget::MARKER_TYPE
          when WorkflowTask::StartTimer
            History::EventTarget::TIMER_TYPE
          when WorkflowTask::CancelTimer
            History::EventTarget::CANCEL_TIMER_REQUEST_TYPE
          when WorkflowTask::CompleteWorkflow, WorkflowTask::FailWorkflow
            History::EventTarget::WORKFLOW_TYPE
          when WorkflowTask::StartChildWorkflow
            History::EventTarget::CHILD_WORKFLOW_TYPE
          end

        History::EventTarget.new(workflow_task_id, target_type)
      end

      def dispatch(target, name, *attributes)
        dispatcher.dispatch(target, name, attributes)
      end

      def discard_workflow_task(workflow_task_id)
        workflow_tasks.delete_if { |(id, _)| id == workflow_task_id }
      end

      def handle_marker(id, type, details)
        marker_ids << id

        case type
        when SIDE_EFFECT_MARKER
          side_effects << [id, details]
        when RELEASE_MARKER
          releases[details] = true
        else
          raise UnsupportedMarkerType, event.type
        end
      end

      def track_release(release_name)
        # replay does not allow untracked (via marker) releases
        if replay?
          releases[release_name] = false
        else
          releases[release_name] = true
          schedule(WorkflowTask::RecordMarker.new(name: RELEASE_MARKER, details: release_name))
        end
      end

      def safe_parse(payload)
        binary = payload.payloads.first.data
        JSON.deserialize(binary)
      end
    end
  end
end
