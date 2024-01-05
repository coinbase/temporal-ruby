require 'temporal/workflow'
require 'temporal/workflow/dispatcher'
require 'temporal/workflow/history/event'
require 'temporal/workflow/history/window'
require 'temporal/workflow/signal'
require 'temporal/workflow/state_manager'
require 'temporal/errors'

describe Temporal::Workflow::StateManager do
  describe '#schedule' do
    class MyWorkflow < Temporal::Workflow; end

    # These are all "terminal" commands
    [
      Temporal::Workflow::Command::ContinueAsNew.new(
        workflow_type: MyWorkflow,
        task_queue: 'dummy'
      ),
      Temporal::Workflow::Command::FailWorkflow.new(
        exception: StandardError.new('dummy')
      ),
      Temporal::Workflow::Command::CompleteWorkflow.new(
        result: 5
      )
    ].each do |terminal_command|
      it "fails to validate if #{terminal_command.class} is not the last command scheduled" do
        state_manager = described_class.new(Temporal::Workflow::Dispatcher.new, Temporal::Configuration.new)

        next_command = Temporal::Workflow::Command::RecordMarker.new(
          name: Temporal::Workflow::StateManager::RELEASE_MARKER,
          details: 'dummy'
        )

        state_manager.schedule(terminal_command)
        expect do
          state_manager.schedule(next_command)
        end.to raise_error(Temporal::WorkflowAlreadyCompletingError)
      end
    end
  end

  describe '#apply' do
    let(:dispatcher) { Temporal::Workflow::Dispatcher.new }
    let(:state_manager) do
      Temporal::Workflow::StateManager.new(dispatcher, config)
    end
    let(:config) { Temporal::Configuration.new }
    let(:connection) { instance_double('Temporal::Connection::GRPC') }
    let(:system_info) { Fabricate(:api_get_system_info) }

    before do
      allow(Temporal::Connection).to receive(:generate).and_return(connection)
    end

    context 'workflow execution started' do
      let(:history) do
        Temporal::Workflow::History.new([Fabricate(:api_workflow_execution_started_event, event_id: 1)])
      end

      it 'dispatcher invoked for start' do
        expect(dispatcher).to receive(:dispatch).with(
          Temporal::Workflow::History::EventTarget.workflow, 'started', instance_of(Array)
        ).once
        state_manager.apply(history.next_window)
      end
    end

    context 'workflow execution started with signal' do
      let(:signal_entry) { Fabricate(:api_workflow_execution_signaled_event, event_id: 2) }
      let(:history) do
        Temporal::Workflow::History.new(
          [
            Fabricate(:api_workflow_execution_started_event, event_id: 1),
            signal_entry
          ]
        )
      end

      it 'dispatcher invoked for start' do
        allow(connection).to receive(:get_system_info).and_return(system_info)

        expect(dispatcher).to receive(:dispatch).with(
          Temporal::Workflow::Signal.new(signal_entry.workflow_execution_signaled_event_attributes.signal_name),
          'signaled',
          [
            signal_entry.workflow_execution_signaled_event_attributes.signal_name,
            signal_entry.workflow_execution_signaled_event_attributes.input
          ]
        ).once.ordered
        expect(dispatcher).to receive(:dispatch).with(
          Temporal::Workflow::History::EventTarget.workflow, 'started', instance_of(Array)
        ).once.ordered

        state_manager.apply(history.next_window)
      end
    end

    context 'workflow execution started with signal, replaying without flag' do
      let(:signal_entry) { Fabricate(:api_workflow_execution_signaled_event, event_id: 2) }
      let(:history) do
        Temporal::Workflow::History.new(
          [
            Fabricate(:api_workflow_execution_started_event, event_id: 1),
            signal_entry,
            Fabricate(:api_workflow_task_scheduled_event, event_id: 3),
            Fabricate(:api_workflow_task_started_event, event_id: 4),
            Fabricate(
              :api_workflow_task_completed_event,
              event_id: 5,
              sdk_flags: sdk_flags
            )
          ]
        )
      end

      context 'replaying without HANDLE_SIGNALS_FIRST sdk flag' do
        let(:sdk_flags) { [] }
        it 'dispatcher invokes start before signal' do
          allow(connection).to receive(:get_system_info).and_return(system_info)

          expect(dispatcher).to receive(:dispatch).with(
            Temporal::Workflow::History::EventTarget.workflow, 'started', instance_of(Array)
          ).once.ordered
          expect(dispatcher).to receive(:dispatch).with(
            Temporal::Workflow::Signal.new(signal_entry.workflow_execution_signaled_event_attributes.signal_name),
            'signaled',
            [
              signal_entry.workflow_execution_signaled_event_attributes.signal_name,
              signal_entry.workflow_execution_signaled_event_attributes.input
            ]
          ).once.ordered

          state_manager.apply(history.next_window)
        end
      end

      context 'replaying without SAVE_FIRST_TASK_SIGNALS sdk flag' do
        let(:sdk_flags) { [Temporal::Workflow::SDKFlags::HANDLE_SIGNALS_FIRST] }
        it 'dispatcher invokes start before signal' do
          allow(connection).to receive(:get_system_info).and_return(system_info)

          expect(dispatcher).to receive(:dispatch).with(
            Temporal::Workflow::History::EventTarget.workflow, 'started', instance_of(Array)
          ).once.ordered
          expect(dispatcher).to receive(:dispatch).with(
            Temporal::Workflow::Signal.new(signal_entry.workflow_execution_signaled_event_attributes.signal_name),
            'signaled',
            [
              signal_entry.workflow_execution_signaled_event_attributes.signal_name,
              signal_entry.workflow_execution_signaled_event_attributes.input
            ]
          ).once.ordered

          state_manager.apply(history.next_window)
        end
      end

      context 'replaying with SAVE_FIRST_TASK_SIGNALS sdk flag' do
        let(:sdk_flags) do [
            Temporal::Workflow::SDKFlags::HANDLE_SIGNALS_FIRST,
            Temporal::Workflow::SDKFlags::SAVE_FIRST_TASK_SIGNALS
          ]
        end
        it 'dispatcher invokes signal before start' do
          allow(connection).to receive(:get_system_info).and_return(system_info)

          expect(dispatcher).to receive(:dispatch).with(
            Temporal::Workflow::Signal.new(signal_entry.workflow_execution_signaled_event_attributes.signal_name),
            'signaled',
            [
              signal_entry.workflow_execution_signaled_event_attributes.signal_name,
              signal_entry.workflow_execution_signaled_event_attributes.input
            ]
          ).once.ordered
          expect(dispatcher).to receive(:dispatch).with(
            Temporal::Workflow::History::EventTarget.workflow, 'started', instance_of(Array)
          ).once.ordered

          state_manager.apply(history.next_window)
        end
      end
    end

    context 'with a marker' do
      let(:activity_entry) { Fabricate(:api_activity_task_scheduled_event, event_id: 5) }
      let(:marker_entry) { Fabricate(:api_marker_recorded_event, event_id: 8) }
      let(:history) do
        Temporal::Workflow::History.new(
          [
            Fabricate(:api_workflow_execution_started_event, event_id: 1),
            Fabricate(:api_workflow_task_scheduled_event, event_id: 2),
            Fabricate(:api_workflow_task_started_event, event_id: 3),
            Fabricate(:api_workflow_task_completed_event, event_id: 4),
            activity_entry,
            Fabricate(:api_activity_task_started_event, event_id: 6),
            Fabricate(:api_activity_task_completed_event, event_id: 7),
            marker_entry,
            Fabricate(:api_workflow_task_scheduled_event, event_id: 9),
            Fabricate(:api_workflow_task_started_event, event_id: 10),
            Fabricate(:api_workflow_task_completed_event, event_id: 11)
          ]
        )
      end

      it 'marker handled first' do
        activity_target = nil
        dispatcher.register_handler(Temporal::Workflow::History::EventTarget.workflow, 'started') do
          activity_target, = state_manager.schedule(
            Temporal::Workflow::Command::ScheduleActivity.new(
              activity_id: activity_entry.event_id,
              activity_type: activity_entry.activity_task_scheduled_event_attributes.activity_type,
              input: nil,
              task_queue: activity_entry.activity_task_scheduled_event_attributes.task_queue,
              retry_policy: nil,
              timeouts: nil,
              headers: nil
            )
          )
        end

        # First task: starts workflow execution, schedules an activity
        state_manager.apply(history.next_window)

        expect(activity_target).not_to be_nil

        activity_completed = false
        dispatcher.register_handler(activity_target, 'completed') do
          activity_completed = true
          state_manager.schedule(
            Temporal::Workflow::Command::RecordMarker.new(
              name: marker_entry.marker_recorded_event_attributes.marker_name,
              details: to_payload_map({})
            )
          )

          # Activity completed event comes before marker recorded event in history, but
          # when activity completion is handled, the marker has already been handled.
          expect(state_manager.send(:marker_ids).count).to eq(1)
        end

        # Second task: Handles activity completion, records marker
        state_manager.apply(history.next_window)

        expect(activity_completed).to eq(true)
      end
    end

    def test_order(signal_first)
      activity_target = nil
      signaled = false

      dispatcher.register_handler(Temporal::Workflow::History::EventTarget.workflow, 'started') do
        activity_target, = state_manager.schedule(
          Temporal::Workflow::Command::ScheduleActivity.new(
            activity_id: activity_entry.event_id,
            activity_type: activity_entry.activity_task_scheduled_event_attributes.activity_type,
            input: nil,
            task_queue: activity_entry.activity_task_scheduled_event_attributes.task_queue,
            retry_policy: nil,
            timeouts: nil,
            headers: nil
          )
        )
      end

      dispatcher.register_handler(
        Temporal::Workflow::Signal.new(
          signal_entry.workflow_execution_signaled_event_attributes.signal_name
        ),
        'signaled'
      ) do
        signaled = true
      end

      # First task: starts workflow execution, schedules an activity
      state_manager.apply(history.next_window)

      expect(activity_target).not_to be_nil
      expect(signaled).to eq(false)

      activity_completed = false
      dispatcher.register_handler(activity_target, 'completed') do
        activity_completed = true

        expect(signaled).to eq(signal_first)
      end

      # Second task: Handles activity completion, signal
      state_manager.apply(history.next_window)

      expect(activity_completed).to eq(true)
      expect(signaled).to eq(true)
    end

    context 'replaying with a signal' do
      let(:activity_entry) { Fabricate(:api_activity_task_scheduled_event, event_id: 5) }
      let(:signal_entry) { Fabricate(:api_workflow_execution_signaled_event, event_id: 8) }
      let(:signal_handling_task) { Fabricate(:api_workflow_task_completed_event, event_id: 11) }
      let(:history) do
        Temporal::Workflow::History.new(
          [
            Fabricate(:api_workflow_execution_started_event, event_id: 1),
            Fabricate(:api_workflow_task_scheduled_event, event_id: 2),
            Fabricate(:api_workflow_task_started_event, event_id: 3),
            Fabricate(:api_workflow_task_completed_event, event_id: 4),
            activity_entry,
            Fabricate(:api_activity_task_started_event, event_id: 6),
            Fabricate(:api_activity_task_completed_event, event_id: 7),
            signal_entry,
            Fabricate(:api_workflow_task_scheduled_event, event_id: 9),
            Fabricate(:api_workflow_task_started_event, event_id: 10),
            signal_handling_task
          ]
        )
      end

      context 'no SDK flag' do
        it 'signal inline' do
          test_order(false)
        end
      end

      context 'with SDK flag' do
        let(:signal_handling_task) do
          Fabricate(
            :api_workflow_task_completed_event,
            event_id: 11,
            sdk_flags: [Temporal::Workflow::SDKFlags::HANDLE_SIGNALS_FIRST]
          )
        end
        it 'signal first' do
          allow(connection).to receive(:get_system_info).and_return(system_info)

          test_order(true)
        end

        context 'even with legacy config enabled' do
          let(:config) { Temporal::Configuration.new.tap { |c| c.legacy_signals = true } }
          it 'signal first' do
            allow(connection).to receive(:get_system_info).and_return(system_info)

            test_order(true)
          end
        end
      end
    end

    context 'not replaying with a signal' do
      let(:activity_entry) { Fabricate(:api_activity_task_scheduled_event, event_id: 5) }
      let(:signal_entry) { Fabricate(:api_workflow_execution_signaled_event, event_id: 8) }
      let(:history) do
        Temporal::Workflow::History.new(
          [
            Fabricate(:api_workflow_execution_started_event, event_id: 1),
            Fabricate(:api_workflow_task_scheduled_event, event_id: 2),
            Fabricate(:api_workflow_task_started_event, event_id: 3),
            Fabricate(:api_workflow_task_completed_event, event_id: 4),
            activity_entry,
            Fabricate(:api_activity_task_started_event, event_id: 6),
            Fabricate(:api_activity_task_completed_event, event_id: 7),
            signal_entry,
            Fabricate(:api_workflow_task_scheduled_event, event_id: 9)
          ]
        )
      end

      context 'signals first config disabled' do
        let(:config) { Temporal::Configuration.new.tap { |c| c.legacy_signals = true } }
        it 'signal inline' do
          test_order(false)

          expect(state_manager.new_sdk_flags_used).to be_empty
        end
      end

      context 'signals first with default config' do
        let(:config) { Temporal::Configuration.new }

        it 'signal first' do
          allow(connection).to receive(:get_system_info).and_return(system_info)

          test_order(true)

          expect(state_manager.new_sdk_flags_used).to eq(Set.new([Temporal::Workflow::SDKFlags::HANDLE_SIGNALS_FIRST]))
        end
      end
    end

    context 'not replaying with a signal in the first workflow task' do
      let(:signal_entry) { Fabricate(:api_workflow_execution_signaled_event, event_id: 2) }
      let(:history) do
        Temporal::Workflow::History.new(
          [
            Fabricate(:api_workflow_execution_started_event, event_id: 1),
            signal_entry,
            Fabricate(:api_workflow_task_scheduled_event, event_id: 3)
          ]
        )
      end

      def test_order_one_task(*expected_sdk_flags)
        allow(connection).to receive(:get_system_info).and_return(system_info)
        signaled = false

        dispatcher.register_handler(
          Temporal::Workflow::Signal.new(
            signal_entry.workflow_execution_signaled_event_attributes.signal_name
          ),
          'signaled'
        ) do
          signaled = true
        end

        state_manager.apply(history.next_window)
        expect(state_manager.new_sdk_flags_used).to eq(Set.new(expected_sdk_flags))
        expect(signaled).to eq(true)
      end

      context 'default config' do
        let(:config) { Temporal::Configuration.new }

        it 'signal first' do
          test_order_one_task(
            Temporal::Workflow::SDKFlags::SAVE_FIRST_TASK_SIGNALS
          )
        end
      end

      context 'signals in first task disabled' do
        let(:config) { Temporal::Configuration.new.tap { |c| c.no_signals_in_first_task = true } }
        it 'signal inline' do
          test_order_one_task(Temporal::Workflow::SDKFlags::HANDLE_SIGNALS_FIRST)
        end
      end
    end
  end

  describe '#history_size' do
    let(:config) { Temporal::Configuration.new }
    let(:history_size_bytes) { 27 }
    let(:suggest_continue_as_new) { true }
    let(:start_workflow_execution_event) { Fabricate(:api_workflow_execution_started_event) }
    let(:workflow_task_scheduled_event) { Fabricate(:api_workflow_task_scheduled_event, event_id: 2) }
    let(:workflow_task_started_event) do
      Fabricate(
        :api_workflow_task_started_event,
        event_id: 3,
        history_size_bytes: history_size_bytes,
        suggest_continue_as_new: suggest_continue_as_new)
    end

    it 'has correct event count' do
      state_manager = described_class.new(Temporal::Workflow::Dispatcher.new, config)

      window = Temporal::Workflow::History::Window.new
      window.add(Temporal::Workflow::History::Event.new(start_workflow_execution_event))
      window.add(Temporal::Workflow::History::Event.new(workflow_task_scheduled_event))
      window.add(Temporal::Workflow::History::Event.new(workflow_task_started_event))

      state_manager.apply(window)

      expect(state_manager.history_size).to eq(
        Temporal::Workflow::History::Size.new(
          events: 4, # comes from event id of started + 1
          bytes: history_size_bytes,
          suggest_continue_as_new: suggest_continue_as_new
        )
      )
    end
  end

  describe "#final_commands" do
    let(:dispatcher) { Temporal::Workflow::Dispatcher.new }
    let(:state_manager) do
      Temporal::Workflow::StateManager.new(dispatcher, config)
    end

    let(:config) { Temporal::Configuration.new }

    it "preserves canceled activity or timer commands when not completed" do
      schedule_activity_command = Temporal::Workflow::Command::ScheduleActivity.new
      state_manager.schedule(schedule_activity_command)

      start_timer_command = Temporal::Workflow::Command::StartTimer.new
      state_manager.schedule(start_timer_command)

      cancel_activity_command = Temporal::Workflow::Command::RequestActivityCancellation.new(
        activity_id: schedule_activity_command.activity_id
      )
      state_manager.schedule(cancel_activity_command)

      cancel_timer_command = Temporal::Workflow::Command::CancelTimer.new(
        timer_id: start_timer_command.timer_id
      )
      state_manager.schedule(cancel_timer_command)

      expect(state_manager.final_commands).to(
        eq(
          [
            [1, schedule_activity_command],
            [2, start_timer_command],
            [3, cancel_activity_command],
            [4, cancel_timer_command]
          ]
        )
      )
    end

    it "drop cancel activity command when completed" do
      schedule_activity_command = Temporal::Workflow::Command::ScheduleActivity.new
      state_manager.schedule(schedule_activity_command)

      cancel_command = Temporal::Workflow::Command::RequestActivityCancellation.new(
        activity_id: schedule_activity_command.activity_id
      )
      state_manager.schedule(cancel_command)

      # Fake completing the activity
      window = Temporal::Workflow::History::Window.new
      # The fake assumes an activity event completed two events ago, so fix the event id to +2
      window.add(
        Temporal::Workflow::History::Event.new(
          Fabricate(:api_activity_task_completed_event, event_id: schedule_activity_command.activity_id + 2)
        )
      )
      state_manager.apply(window)

      expect(state_manager.final_commands).to(eq([[1, schedule_activity_command]]))
    end

    it "drop cancel timer command when completed" do
      start_timer_command = Temporal::Workflow::Command::StartTimer.new
      state_manager.schedule(start_timer_command)

      cancel_command = Temporal::Workflow::Command::CancelTimer.new(
        timer_id: start_timer_command.timer_id
      )
      state_manager.schedule(cancel_command)

      # Fake completing the timer
      window = Temporal::Workflow::History::Window.new
      # The fake assumes an activity event completed four events ago, so fix the event id to +4
      window.add(
        Temporal::Workflow::History::Event.new(
          Fabricate(:api_timer_fired_event, event_id: start_timer_command.timer_id + 4)
        )
      )
      state_manager.apply(window)

      expect(state_manager.final_commands).to(eq([[1, start_timer_command]]))
    end
  end


  describe '#search_attributes' do
    let(:initial_search_attributes) do
      {
        'CustomAttribute1' => 42,
        'CustomAttribute2' => 10
      }
    end
    let(:start_workflow_execution_event) do
      Fabricate(:api_workflow_execution_started_event, search_attributes: initial_search_attributes)
    end
    let(:start_workflow_execution_event_no_search_attributes) do
      Fabricate(:api_workflow_execution_started_event)
    end
    let(:workflow_task_started_event) { Fabricate(:api_workflow_task_started_event, event_id: 2) }
    let(:upserted_attributes_1) do
      {
        'CustomAttribute3' => 'foo',
        'CustomAttribute2' => 8
      }
    end
    let(:upsert_search_attribute_event_1) do
      Fabricate(:api_upsert_search_attributes_event, search_attributes: upserted_attributes_1)
    end
    let(:upserted_attributes_2) do
      {
        'CustomAttribute3' => 'bar',
        'CustomAttribute4' => 10
      }
    end
    let(:upsert_search_attribute_event_2) do
      Fabricate(:api_upsert_search_attributes_event,
                event_id: 4,
                search_attributes: upserted_attributes_2)
    end
    let(:upsert_empty_search_attributes_event) do
      Fabricate(:api_upsert_search_attributes_event, search_attributes: {})
    end

    it 'initial merges with upserted' do
      state_manager = described_class.new(Temporal::Workflow::Dispatcher.new, Temporal::Configuration.new)

      window = Temporal::Workflow::History::Window.new
      window.add(Temporal::Workflow::History::Event.new(start_workflow_execution_event))
      window.add(Temporal::Workflow::History::Event.new(upsert_search_attribute_event_1))

      command = Temporal::Workflow::Command::UpsertSearchAttributes.new(
        search_attributes: upserted_attributes_1
      )

      state_manager.schedule(command)
      # Attributes from command are applied immediately, then merged when
      # history window is replayed below. This ensures newly upserted
      # search attributes are available immediately in workflow code.
      expect(state_manager.search_attributes).to eq(upserted_attributes_1)

      state_manager.apply(window)

      expect(state_manager.search_attributes).to eq(
        {
          'CustomAttribute1' => 42, # from initial (not overridden)
          'CustomAttribute2' => 8, # only from upsert
          'CustomAttribute3' => 'foo' # overridden by upsert
        }
      )
    end

    it 'initial and upsert treated as empty hash' do
      state_manager = described_class.new(Temporal::Workflow::Dispatcher.new, Temporal::Configuration.new)

      window = Temporal::Workflow::History::Window.new
      window.add(Temporal::Workflow::History::Event.new(start_workflow_execution_event_no_search_attributes))
      window.add(Temporal::Workflow::History::Event.new(upsert_empty_search_attributes_event))

      command = Temporal::Workflow::Command::UpsertSearchAttributes.new(search_attributes: {})
      expect(state_manager.search_attributes).to eq({})

      state_manager.schedule(command)
      state_manager.apply(window)

      expect(state_manager.search_attributes).to eq({})
    end

    it 'multiple upserts merge' do
      state_manager = described_class.new(Temporal::Workflow::Dispatcher.new, Temporal::Configuration.new)

      window_1 = Temporal::Workflow::History::Window.new
      window_1.add(Temporal::Workflow::History::Event.new(workflow_task_started_event))
      window_1.add(Temporal::Workflow::History::Event.new(upsert_search_attribute_event_1))

      command_1 = Temporal::Workflow::Command::UpsertSearchAttributes.new(search_attributes: upserted_attributes_1)
      state_manager.schedule(command_1)
      state_manager.apply(window_1)

      expect(state_manager.search_attributes).to eq(upserted_attributes_1)

      window_2 = Temporal::Workflow::History::Window.new
      window_2.add(Temporal::Workflow::History::Event.new(upsert_search_attribute_event_2))

      command_2 = Temporal::Workflow::Command::UpsertSearchAttributes.new(search_attributes: upserted_attributes_2)
      state_manager.schedule(command_2)
      state_manager.apply(window_2)

      expect(state_manager.search_attributes).to eq(
        {
          'CustomAttribute2' => 8,
          'CustomAttribute3' => 'bar',
          'CustomAttribute4' => 10
        }
      )
    end
  end
end
