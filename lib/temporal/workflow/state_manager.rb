require 'set'
require 'temporal/errors'
require 'temporal/workflow/command'
require 'temporal/workflow/command_state_machine'
require 'temporal/workflow/history/event_target'
require 'temporal/concerns/payloads'
require 'temporal/workflow/errors'
require 'temporal/workflow/sdk_flags'
require 'temporal/workflow/signal'

module Temporal
  class Workflow
    class StateManager
      include Concerns::Payloads

      SIDE_EFFECT_MARKER = 'SIDE_EFFECT'.freeze
      RELEASE_MARKER = 'RELEASE'.freeze

      class UnsupportedEvent < Temporal::InternalError; end
      class UnsupportedMarkerType < Temporal::InternalError; end

      attr_reader :commands, :local_time, :search_attributes, :new_sdk_flags_used

      def initialize(dispatcher, config)
        @dispatcher = dispatcher
        @commands = []
        @marker_ids = Set.new
        @releases = {}
        @side_effects = []
        @command_tracker = Hash.new { |hash, key| hash[key] = CommandStateMachine.new }
        @last_event_id = 0
        @local_time = nil
        @replay = false
        @search_attributes = {}
        @config = config

        # Current flags in use, built up from workflow task completed history entries
        @sdk_flags = Set.new

        # New flags used when not replaying
        @new_sdk_flags_used = Set.new
      end

      def replay?
        @replay
      end

      def schedule(command)
        # Fast-forward event IDs to skip all the markers (version markers can
        # be removed, so we can't rely on them being scheduled during a replay)
        command_id = next_event_id
        command_id = next_event_id while marker_ids.include?(command_id)

        cancelation_id =
          case command
          when Command::ScheduleActivity
            command.activity_id ||= command_id
          when Command::StartChildWorkflow
            command.workflow_id ||= command_id
          when Command::StartTimer
            command.timer_id ||= command_id
          when Command::UpsertSearchAttributes
            # This allows newly upserted search attributes to be read
            # immediately. Without this, attributes would not be available
            # until the next history window is applied on replay.
            search_attributes.merge!(command.search_attributes)
          end

        state_machine = command_tracker[command_id]
        state_machine.requested if state_machine.state == CommandStateMachine::NEW_STATE

        validate_append_command(command)
        commands << [command_id, command]

        [event_target_from(command_id, command), cancelation_id]
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
        history_window.sdk_flags.each { |flag| sdk_flags.add(flag) }

        order_events(history_window.events).each do |event|
          apply_event(event)
        end
      end

      def self.event_order(event, signals_first)
        if event.type == 'MARKER_RECORDED'
          # markers always come first
          0
        elsif event.type == 'WORKFLOW_EXECUTION_STARTED'
          # This always comes next if present
          1
        elsif signals_first && signal_event?(event)
          # signals come next if we are in signals first mode
          2
        else
          # then everything else
          3
        end
      end

      def self.signal_event?(event)
        event.type == 'WORKFLOW_EXECUTION_SIGNALED'
      end

      private

      attr_reader :dispatcher, :command_tracker, :marker_ids, :side_effects, :releases, :sdk_flags

      def use_signals_first(raw_events)
        if sdk_flags.include?(SDKFlags::HANDLE_SIGNALS_FIRST)
          # If signals were handled first when this task or a previous one in this run were first
          # played, we must continue to do so in order to ensure determinism regardless of what
          # the configuration value is set to. Even the capabilities can be ignored because the
          # server must have returned SDK metadata for this to be true.
          true
        elsif raw_events.any? { |event| StateManager.signal_event?(event) } &&
              # If this is being played for the first time, use the configuration flag to choose
              (!replay? && !@config.legacy_signals) &&
              # In order to preserve determinism, the server must support SDK metadata to order signals
              # first. This is checked last because it will result in a Temporal server call the first
              # time it's called in the worker process.
              @config.capabilities.sdk_metadata
          report_flag_used(SDKFlags::HANDLE_SIGNALS_FIRST)
          true
        else
          false
        end
      end

      def order_events(raw_events)
        signals_first = use_signals_first(raw_events)

        raw_events.sort_by.with_index do |event, index|
          # sort_by is not stable, so include index to preserve order
          [StateManager.event_order(event, signals_first), index]
        end
      end

      def report_flag_used(flag)
        # Only add the flag if it's not already present and we are not replaying
        if !replay? &&
           !sdk_flags.include?(flag) &&
           !new_sdk_flags_used.include?(flag)
          new_sdk_flags_used << flag
          sdk_flags << flag
        end
      end

      def next_event_id
        @last_event_id += 1
      end

      def validate_append_command(command)
        return if commands.last.nil?

        _, previous_command = commands.last
        case previous_command
        when Command::CompleteWorkflow, Command::FailWorkflow, Command::ContinueAsNew
          context_string = case previous_command
                           when Command::CompleteWorkflow
                             'The workflow completed'
                           when Command::FailWorkflow
                             'The workflow failed'
                           when Command::ContinueAsNew
                             'The workflow continued as new'
                           end
          raise Temporal::WorkflowAlreadyCompletingError, "You cannot do anything in a Workflow after it completes. #{context_string}, "\
            "but then it sent a new command: #{command.class}.  This can happen, for example, if you've "\
            'not waited for all of your Activity futures before finishing the Workflow.'
        end
      end

      def apply_event(event)
        state_machine = command_tracker[event.originating_event_id]
        history_target = History::EventTarget.from_event(event)

        case event.type
        when 'WORKFLOW_EXECUTION_STARTED'
          unless event.attributes.search_attributes.nil?
            search_attributes.merge!(from_payload_map(event.attributes.search_attributes&.indexed_fields || {}))
          end

          state_machine.start
          dispatch(
            History::EventTarget.workflow,
            'started',
            from_payloads(event.attributes.input),
            event
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
          discard_command(history_target)

        when 'ACTIVITY_TASK_STARTED'
          state_machine.start

        when 'ACTIVITY_TASK_COMPLETED'
          state_machine.complete
          dispatch(history_target, 'completed', from_result_payloads(event.attributes.result))

        when 'ACTIVITY_TASK_FAILED'
          state_machine.fail
          dispatch(history_target, 'failed',
                   Temporal::Workflow::Errors.generate_error(event.attributes.failure, ActivityException))

        when 'ACTIVITY_TASK_TIMED_OUT'
          state_machine.time_out
          dispatch(history_target, 'failed', Temporal::Workflow::Errors.generate_error(event.attributes.failure))

        when 'ACTIVITY_TASK_CANCEL_REQUESTED'
          state_machine.requested
          discard_command(history_target)

        when 'REQUEST_CANCEL_ACTIVITY_TASK_FAILED'
          state_machine.fail
          discard_command(history_target)
          dispatch(history_target, 'failed', event.attributes.cause, nil)

        when 'ACTIVITY_TASK_CANCELED'
          state_machine.cancel
          dispatch(history_target, 'failed',
                   Temporal::ActivityCanceled.new(from_details_payloads(event.attributes.details)))

        when 'TIMER_STARTED'
          state_machine.start
          discard_command(history_target)

        when 'TIMER_FIRED'
          state_machine.complete
          dispatch(history_target, 'fired')

        when 'CANCEL_TIMER_FAILED'
          state_machine.failed
          discard_command(history_target)
          dispatch(history_target, 'failed', event.attributes.cause, nil)

        when 'TIMER_CANCELED'
          state_machine.cancel
          discard_command(history_target)
          dispatch(history_target, 'canceled')

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
          # relies on Signal#== for matching in Dispatcher
          signal_target = Signal.new(event.attributes.signal_name)
          dispatch(signal_target, 'signaled', event.attributes.signal_name,
                   from_signal_payloads(event.attributes.input))

        when 'WORKFLOW_EXECUTION_TERMINATED'
          # todo

        when 'WORKFLOW_EXECUTION_CONTINUED_AS_NEW'
          # todo

        when 'START_CHILD_WORKFLOW_EXECUTION_INITIATED'
          state_machine.schedule
          discard_command(history_target)

        when 'START_CHILD_WORKFLOW_EXECUTION_FAILED'
          state_machine.fail
          error = Temporal::Workflow::Errors.generate_error_for_child_workflow_start(
            event.attributes.cause,
            event.attributes.workflow_id
          )
          dispatch(history_target, 'failed', error)
        when 'CHILD_WORKFLOW_EXECUTION_STARTED'
          dispatch(history_target, 'started', event.attributes.workflow_execution)
          state_machine.start

        when 'CHILD_WORKFLOW_EXECUTION_COMPLETED'
          state_machine.complete
          dispatch(history_target, 'completed', from_result_payloads(event.attributes.result))

        when 'CHILD_WORKFLOW_EXECUTION_FAILED'
          state_machine.fail
          dispatch(history_target, 'failed', Temporal::Workflow::Errors.generate_error(event.attributes.failure))

        when 'CHILD_WORKFLOW_EXECUTION_CANCELED'
          state_machine.cancel
          dispatch(history_target, 'failed', Temporal::Workflow::Errors.generate_error(event.attributes.failure))

        when 'CHILD_WORKFLOW_EXECUTION_TIMED_OUT'
          state_machine.time_out
          dispatch(history_target, 'failed',
                   ChildWorkflowTimeoutError.new('The child workflow timed out before succeeding'))

        when 'CHILD_WORKFLOW_EXECUTION_TERMINATED'
          state_machine.terminated
          dispatch(history_target, 'failed', ChildWorkflowTerminatedError.new('The child workflow was terminated'))
        when 'SIGNAL_EXTERNAL_WORKFLOW_EXECUTION_INITIATED'
          # Temporal Server will try to Signal the targeted Workflow
          # Contains the Signal name, as well as a Signal payload
          # The workflow that sends the signal creates this event in its log; the
          # receiving workflow records WORKFLOW_EXECUTION_SIGNALED on reception
          state_machine.start
          discard_command(history_target)

        when 'SIGNAL_EXTERNAL_WORKFLOW_EXECUTION_FAILED'
          # Temporal Server cannot Signal the targeted Workflow
          # Usually because the Workflow could not be found
          state_machine.fail
          dispatch(history_target, 'failed', 'StandardError', event.attributes.cause)

        when 'EXTERNAL_WORKFLOW_EXECUTION_SIGNALED'
          # Temporal Server has successfully Signaled the targeted Workflow
          # Return the result to the Future waiting on this
          state_machine.complete
          dispatch(history_target, 'completed')

        when 'UPSERT_WORKFLOW_SEARCH_ATTRIBUTES'
          search_attributes.merge!(from_payload_map(event.attributes.search_attributes&.indexed_fields || {}))
          # no need to track state; this is just a synchronous API call.
          discard_command(history_target)

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
          when Command::UpsertSearchAttributes
            History::EventTarget::UPSERT_SEARCH_ATTRIBUTES_REQUEST_TYPE
          when Command::SignalExternalWorkflow
            History::EventTarget::EXTERNAL_WORKFLOW_TYPE
          end

        History::EventTarget.new(command_id, target_type)
      end

      def dispatch(history_target, name, *attributes)
        dispatcher.dispatch(history_target, name, attributes)
      end

      NONDETERMINISM_ERROR_SUGGESTION =
        'Likely, either you have made a version-unsafe change to your workflow or have non-deterministic '\
        'behavior in your workflow.  See https://docs.temporal.io/docs/java/versioning/#introduction-to-versioning.'.freeze

      def discard_command(history_target)
        # Pop the first command from the list, it is expected to match
        replay_command_id, replay_command = commands.shift

        unless replay_command_id
          raise NonDeterministicWorkflowError,
                "A command in the history of previous executions, #{history_target}, was not scheduled upon replay. " + NONDETERMINISM_ERROR_SUGGESTION
        end

        replay_target = event_target_from(replay_command_id, replay_command)
        if history_target != replay_target
          raise NonDeterministicWorkflowError,
                "Unexpected command.  The replaying code is issuing: #{replay_target}, "\
                "but the history of previous executions recorded: #{history_target}. " + NONDETERMINISM_ERROR_SUGGESTION
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
    end
  end
end
