require 'set'
require 'temporal/errors'
require 'temporal/workflow/command'
require 'temporal/workflow/command_state_machine'
require 'temporal/workflow/history/event_target'
require 'temporal/metadata'
require 'temporal/concerns/payloads'

module Temporal
  class Workflow
    class StateManager
      include Concerns::Payloads

      SIDE_EFFECT_MARKER = 'SIDE_EFFECT'.freeze
      RELEASE_MARKER = 'RELEASE'.freeze

      class UnsupportedEvent < Temporal::InternalError; end
      class UnsupportedMarkerType < Temporal::InternalError; end

      attr_reader :commands, :local_time

      def initialize(dispatcher)
        @dispatcher = dispatcher
        @commands = []
        @marker_ids = Set.new
        @releases = {}
        @side_effects = []
        @command_tracker = Hash.new { |hash, key| hash[key] = CommandStateMachine.new }
        @last_event_id = 0
        @local_time = nil
        @replay = false
      end

      def replay?
        @replay
      end

      def schedule(command)
        # Fast-forward event IDs to skip all the markers (version markers can
        # be removed, so we can't rely on them being scheduled during a replay)
        command_id = next_event_id
        while marker_ids.include?(command_id) do
          command_id = next_event_id
        end

        cancelation_id =
          case command
          when Command::ScheduleActivity
            command.activity_id ||= command_id
          when Command::StartChildWorkflow
            command.workflow_id ||= command_id
          when Command::StartTimer
            command.timer_id ||= command_id
          end

        state_machine = command_tracker[command_id]
        state_machine.requested if state_machine.state == CommandStateMachine::NEW_STATE

        commands << [command_id, command]

        return [event_target_from(command_id, command), cancelation_id]
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

      attr_reader :dispatcher, :command_tracker, :marker_ids, :side_effects, :releases

      def next_event_id
        @last_event_id += 1
      end

      def apply_event(event)
        state_machine = command_tracker[event.originating_event_id]
        target = History::EventTarget.from_event(event)

        case event.type
        when 'WORKFLOW_EXECUTION_STARTED'
          state_machine.start
          dispatch(
            History::EventTarget.workflow,
            'started',
            from_payloads(event.attributes.input),
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
          discard_command(target)

        when 'ACTIVITY_TASK_STARTED'
          state_machine.start

        when 'ACTIVITY_TASK_COMPLETED'
          state_machine.complete
          dispatch(target, 'completed', from_result_payloads(event.attributes.result))

        when 'ACTIVITY_TASK_FAILED'
          state_machine.fail
          dispatch(target, 'failed', parse_failure(event.attributes.failure, ActivityException))

        when 'ACTIVITY_TASK_TIMED_OUT'
          state_machine.time_out
          dispatch(target, 'failed', parse_failure(event.attributes.failure))

        when 'ACTIVITY_TASK_CANCEL_REQUESTED'
          state_machine.requested
          discard_command(target)

        when 'REQUEST_CANCEL_ACTIVITY_TASK_FAILED'
          state_machine.fail
          dispatch(target, 'failed', event.attributes.cause, nil)

        when 'ACTIVITY_TASK_CANCELED'
          state_machine.cancel
          dispatch(target, 'failed', parse_failure(event.attributes.failure))

        when 'TIMER_STARTED'
          state_machine.start
          discard_command(target)

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
          handle_marker(event.id, event.attributes.marker_name, from_details_payloads(event.attributes.details['data']))

        when 'WORKFLOW_EXECUTION_SIGNALED'
          dispatch(target, 'signaled', event.attributes.signal_name, from_payloads(event.attributes.input))

        when 'WORKFLOW_EXECUTION_TERMINATED'
          # todo

        when 'WORKFLOW_EXECUTION_CONTINUED_AS_NEW'
          # todo

        when 'START_CHILD_WORKFLOW_EXECUTION_INITIATED'
          state_machine.schedule
          discard_command(target)

        when 'START_CHILD_WORKFLOW_EXECUTION_FAILED'
          state_machine.fail
          dispatch(target, 'failed', 'StandardError', from_payloads(event.attributes.cause))

        when 'CHILD_WORKFLOW_EXECUTION_STARTED'
          state_machine.start

        when 'CHILD_WORKFLOW_EXECUTION_COMPLETED'
          state_machine.complete
          dispatch(target, 'completed', from_result_payloads(event.attributes.result))

        when 'CHILD_WORKFLOW_EXECUTION_FAILED'
          state_machine.fail
          dispatch(target, 'failed', parse_failure(event.attributes.failure))

        when 'CHILD_WORKFLOW_EXECUTION_CANCELED'
          state_machine.cancel
          dispatch(target, 'failed', parse_failure(event.attributes.failure))

        when 'CHILD_WORKFLOW_EXECUTION_TIMED_OUT'
          state_machine.time_out
          dispatch(target, 'failed', parse_failure(event.attributes.failure))

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

      def event_target_from(command_id, command)
        target_type =
          case command
          when Command::ScheduleActivity
            History::EventTarget::ACTIVITY_TYPE
          when Command::RequestActivityCancellation
            History::EventTarget::CANCEL_ACTIVITY_REQUEST_TYPE
          when Command::RecordMarker
            History::EventTarget::MARKER_TYPE
          when Command::StartTimer
            History::EventTarget::TIMER_TYPE
          when Command::CancelTimer
            History::EventTarget::CANCEL_TIMER_REQUEST_TYPE
          when Command::CompleteWorkflow, Command::FailWorkflow
            History::EventTarget::WORKFLOW_TYPE
          when Command::StartChildWorkflow
            History::EventTarget::CHILD_WORKFLOW_TYPE
          end

        History::EventTarget.new(command_id, target_type)
      end

      def dispatch(target, name, *attributes)
        dispatcher.dispatch(target, name, attributes)
      end

      def discard_command(target)
        # Pop the first command from the list, it is expected to match
        existing_command_id, existing_command = commands.shift

        if !existing_command_id
          raise NonDeterministicWorkflowError, "A command #{target} was not scheduled upon replay"
        end

        existing_target = event_target_from(existing_command_id, existing_command)
        if target != existing_target
          raise NonDeterministicWorkflowError, "Unexpected command #{existing_target} (expected #{target})"
        end
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
          schedule(Command::RecordMarker.new(name: RELEASE_MARKER, details: release_name))
        end
      end

      def parse_failure(failure, default_exception_class = StandardError)
        case failure.failure_info
        when :application_failure_info
          exception_class = safe_constantize(failure.application_failure_info.type)
          exception_class ||= default_exception_class
          details = from_payloads(failure.application_failure_info.details)
          backtrace = failure.stack_trace.split("\n")

          exception_class.new(details).tap do |exception|
            exception.set_backtrace(backtrace) if !backtrace.empty?
          end
        when :timeout_failure_info
          TimeoutError.new("Timeout type: #{failure.timeout_failure_info.timeout_type.to_s}")
        when :canceled_failure_info
          # TODO: Distinguish between different entity cancellations
          StandardError.new(from_payloads(failure.canceled_failure_info.details))
        else
          StandardError.new(failure.message)
        end
      end

      def safe_constantize(const)
        Object.const_get(const) if Object.const_defined?(const)
      rescue NameError
        nil
      end
    end
  end
end
