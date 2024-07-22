require 'securerandom'
require 'temporal/client'
require 'temporal/configuration'
require 'temporal/workflow'
require 'temporal/workflow/history'
require 'temporal/connection/grpc'
require 'temporal/reset_reapply_type'

describe Temporal::Client do
  subject { described_class.new(config) }

  let(:config) { Temporal::Configuration.new.tap { |c| c.namespace = namespace } }
  let(:connection) { instance_double(Temporal::Connection::GRPC) }
  let(:namespace) { 'default-test-namespace' }
  let(:workflow_id) { SecureRandom.uuid }
  let(:run_id) { SecureRandom.uuid }

  class TestStartWorkflow < Temporal::Workflow
    namespace 'default-test-namespace'
    task_queue 'default-test-task-queue'
  end

  before do
    allow(Temporal::Connection)
    .to receive(:generate)
    .with(config.for_connection)
    .and_return(connection)
  end

  after do
    if subject.instance_variable_get(:@connection)
      subject.remove_instance_variable(:@connection)
    end
  end

  describe '#start_workflow' do
    let(:temporal_response) do
      Temporalio::Api::WorkflowService::V1::StartWorkflowExecutionResponse.new(run_id: 'xxx')
    end

    before { allow(connection).to receive(:start_workflow_execution).and_return(temporal_response) }

    context 'with header propagator' do
      class TestHeaderPropagator
        def inject!(header)
          header['test'] = 'asdf'
        end
      end

      it 'updates the header' do
        config.add_header_propagator(TestHeaderPropagator)
        subject.start_workflow(TestStartWorkflow, 42)
        expect(connection)
          .to have_received(:start_workflow_execution)
                .with(
                  namespace: 'default-test-namespace',
                  workflow_id: an_instance_of(String),
                  workflow_name: 'TestStartWorkflow',
                  task_queue: 'default-test-task-queue',
                  input: [42],
                  task_timeout: Temporal.configuration.timeouts[:task],
                  run_timeout: Temporal.configuration.timeouts[:run],
                  execution_timeout: Temporal.configuration.timeouts[:execution],
                  workflow_id_reuse_policy: nil,
                  headers: { 'test' => 'asdf' },
                  memo: {},
                  search_attributes: {},
                )
      end
    end

    context 'using a workflow class' do
      it 'returns run_id' do
        result = subject.start_workflow(TestStartWorkflow, 42)

        expect(result).to eq(temporal_response.run_id)
      end

      it 'starts a workflow using the default options' do
        subject.start_workflow(TestStartWorkflow, 42)

        expect(connection)
          .to have_received(:start_workflow_execution)
          .with(
            namespace: 'default-test-namespace',
            workflow_id: an_instance_of(String),
            workflow_name: 'TestStartWorkflow',
            task_queue: 'default-test-task-queue',
            input: [42],
            task_timeout: Temporal.configuration.timeouts[:task],
            run_timeout: Temporal.configuration.timeouts[:run],
            execution_timeout: Temporal.configuration.timeouts[:execution],
            workflow_id_reuse_policy: nil,
            headers: {},
            memo: {},
            search_attributes: {},
          )
      end

      it 'starts a workflow using the options specified' do
        subject.start_workflow(
          TestStartWorkflow,
          42,
          options: {
            name: 'test-workflow',
            namespace: 'test-namespace',
            task_queue: 'test-task-queue',
            headers: { 'Foo' => 'Bar' },
            workflow_id_reuse_policy: :reject,
            memo: { 'MemoKey1' => 'MemoValue1' },
            search_attributes: { 'SearchAttribute1' => 256 },
          }
        )

        expect(connection)
          .to have_received(:start_workflow_execution)
          .with(
            namespace: 'test-namespace',
            workflow_id: an_instance_of(String),
            workflow_name: 'test-workflow',
            task_queue: 'test-task-queue',
            input: [42],
            task_timeout: Temporal.configuration.timeouts[:task],
            run_timeout: Temporal.configuration.timeouts[:run],
            execution_timeout: Temporal.configuration.timeouts[:execution],
            workflow_id_reuse_policy: :reject,
            headers: { 'Foo' => 'Bar' },
            memo: { 'MemoKey1' => 'MemoValue1' },
            search_attributes: { 'SearchAttribute1' => 256 },
          )
      end

      it 'starts a workflow using a mix of input, keyword arguments and options' do
        subject.start_workflow(
          TestStartWorkflow,
          42,
          arg_1: 1,
          arg_2: 2,
          options: { name: 'test-workflow' }
        )

        expect(connection)
          .to have_received(:start_workflow_execution)
          .with(
            namespace: 'default-test-namespace',
            workflow_id: an_instance_of(String),
            workflow_name: 'test-workflow',
            task_queue: 'default-test-task-queue',
            input: [42, { arg_1: 1, arg_2: 2 }],
            task_timeout: Temporal.configuration.timeouts[:task],
            run_timeout: Temporal.configuration.timeouts[:run],
            execution_timeout: Temporal.configuration.timeouts[:execution],
            workflow_id_reuse_policy: nil,
            headers: {},
            memo: {},
            search_attributes: {},
          )
      end

      it 'starts a workflow using specified workflow_id' do
        subject.start_workflow(TestStartWorkflow, 42, options: { workflow_id: '123' })

        expect(connection)
          .to have_received(:start_workflow_execution)
          .with(
            namespace: 'default-test-namespace',
            workflow_id: '123',
            workflow_name: 'TestStartWorkflow',
            task_queue: 'default-test-task-queue',
            input: [42],
            task_timeout: Temporal.configuration.timeouts[:task],
            run_timeout: Temporal.configuration.timeouts[:run],
            execution_timeout: Temporal.configuration.timeouts[:execution],
            workflow_id_reuse_policy: nil,
            headers: {},
            memo: {},
            search_attributes: {},
          )
      end

      it 'starts a workflow with a workflow id reuse policy' do
        subject.start_workflow(
          TestStartWorkflow, 42, options: { workflow_id_reuse_policy: :allow }
        )

        expect(connection)
          .to have_received(:start_workflow_execution)
          .with(
            namespace: 'default-test-namespace',
            workflow_id: an_instance_of(String),
            workflow_name: 'TestStartWorkflow',
            task_queue: 'default-test-task-queue',
            input: [42],
            task_timeout: Temporal.configuration.timeouts[:task],
            run_timeout: Temporal.configuration.timeouts[:run],
            execution_timeout: Temporal.configuration.timeouts[:execution],
            workflow_id_reuse_policy: :allow,
            headers: {},
            memo: {},
            search_attributes: {},
          )
      end
    end

    context 'using a string reference' do
      it 'starts a workflow' do
        subject.start_workflow(
          'test-workflow',
          42,
          options: { namespace: 'test-namespace', task_queue: 'test-task-queue' }
        )

        expect(connection)
          .to have_received(:start_workflow_execution)
          .with(
            namespace: 'test-namespace',
            workflow_id: an_instance_of(String),
            workflow_name: 'test-workflow',
            task_queue: 'test-task-queue',
            input: [42],
            task_timeout: Temporal.configuration.timeouts[:task],
            run_timeout: Temporal.configuration.timeouts[:run],
            execution_timeout: Temporal.configuration.timeouts[:execution],
            workflow_id_reuse_policy: nil,
            headers: {},
            memo: {},
            search_attributes: {},
          )
      end
    end
  end

  describe '#start_workflow with a signal' do
    let(:temporal_response) do
      Temporalio::Api::WorkflowService::V1::SignalWithStartWorkflowExecutionResponse.new(run_id: 'xxx')
    end

    before { allow(connection).to receive(:signal_with_start_workflow_execution).and_return(temporal_response) }

    def expect_signal_with_start(expected_arguments, expected_signal_argument)
      expect(connection)
        .to have_received(:signal_with_start_workflow_execution)
        .with(
          namespace: 'default-test-namespace',
          workflow_id: an_instance_of(String),
          workflow_name: 'TestStartWorkflow',
          task_queue: 'default-test-task-queue',
          input: expected_arguments,
          task_timeout: Temporal.configuration.timeouts[:task],
          run_timeout: Temporal.configuration.timeouts[:run],
          execution_timeout: Temporal.configuration.timeouts[:execution],
          workflow_id_reuse_policy: nil,
          headers: {},
          memo: {},
          search_attributes: {},
          signal_name: 'the question',
          signal_input: expected_signal_argument,
        )
    end

    it 'starts a workflow with a signal and no arguments' do
      subject.start_workflow(
        TestStartWorkflow,
        options: { signal_name: 'the question' }
      )

      expect_signal_with_start([], nil)
    end

    it 'starts a workflow with a signal and one scalar argument' do
      signal_input = 'what do you get if you multiply six by nine?'
      subject.start_workflow(
        TestStartWorkflow,
        42,
        options: {
          signal_name: 'the question',
          signal_input: signal_input,
        }
      )

      expect_signal_with_start([42], signal_input)
    end

    it 'starts a workflow with a signal and multiple arguments and signal_inputs' do
      signal_input = ['what do you get', 'if you multiply six by nine?']
      subject.start_workflow(
        TestStartWorkflow,
        42,
        43,
        options: {
          signal_name: 'the question',
          # signals can't have multiple scalar args, but you can pass an array
          signal_input: signal_input
        }
      )

      expect_signal_with_start([42, 43], signal_input)
    end

    it 'raises when signal_input is given but signal_name is not' do
      expect do
        subject.start_workflow(
          TestStartWorkflow, 
          [42, 54],
          [43, 55],
          options: { signal_input: 'what do you get if you multiply six by nine?', }
        )
      end.to raise_error(ArgumentError)
    end
  end

  describe '#schedule_workflow' do
    let(:temporal_response) do
      Temporalio::Api::WorkflowService::V1::StartWorkflowExecutionResponse.new(run_id: 'xxx')
    end

    before { allow(connection).to receive(:start_workflow_execution).and_return(temporal_response) }

    it 'starts a cron workflow' do
      subject.schedule_workflow(TestStartWorkflow, '* * * * *', 42)

      expect(connection)
        .to have_received(:start_workflow_execution)
        .with(
          namespace: 'default-test-namespace',
          workflow_id: an_instance_of(String),
          workflow_name: 'TestStartWorkflow',
          task_queue: 'default-test-task-queue',
          cron_schedule: '* * * * *',
          input: [42],
          task_timeout: Temporal.configuration.timeouts[:task],
          run_timeout: Temporal.configuration.timeouts[:run],
          execution_timeout: Temporal.configuration.timeouts[:execution],
          workflow_id_reuse_policy: nil,
          memo: {},
          search_attributes: {},
          headers: {},
        )
    end
  end

  describe '#register_namespace' do
    before { allow(connection).to receive(:register_namespace).and_return(nil) }

    it 'registers namespace with the specified name' do
      subject.register_namespace('new-namespace')

      expect(connection)
        .to have_received(:register_namespace)
        .with(name: 'new-namespace', description: nil, is_global: false, data: nil, retention_period: 10)
    end

    it 'registers namespace with the specified name and description' do
      subject.register_namespace('new-namespace', 'namespace description')

      expect(connection)
        .to have_received(:register_namespace)
        .with(name: 'new-namespace', description: 'namespace description', is_global: false, data: nil, retention_period: 10)
    end
  end

  describe '#describe_namespace' do
    before { allow(connection).to receive(:describe_namespace).and_return(Temporalio::Api::WorkflowService::V1::DescribeNamespaceResponse.new) }
    
    it 'passes the namespace to the connection' do
      result = subject.describe_namespace('new-namespace')

      expect(connection)
        .to have_received(:describe_namespace)
        .with(name: 'new-namespace')
    end
  end

  describe '#signal_workflow' do
    before { allow(connection).to receive(:signal_workflow_execution).and_return(nil) }

    it 'signals workflow with a specified class' do
      subject.signal_workflow(TestStartWorkflow, 'signal', 'workflow_id', 'run_id')

      expect(connection)
        .to have_received(:signal_workflow_execution)
        .with(
          namespace: 'default-test-namespace',
          signal: 'signal', 
          workflow_id: 'workflow_id',
          run_id: 'run_id',
          input: nil,
        )
    end

    it 'signals workflow with input' do
      subject.signal_workflow(TestStartWorkflow, 'signal', 'workflow_id', 'run_id', 'input')

      expect(connection)
        .to have_received(:signal_workflow_execution)
        .with(
          namespace: 'default-test-namespace',
          signal: 'signal', 
          workflow_id: 'workflow_id',
          run_id: 'run_id',
          input: 'input',
        )
    end

    it 'signals workflow with a specified namespace' do
      subject.signal_workflow(TestStartWorkflow, 'signal', 'workflow_id', 'run_id', namespace: 'other-test-namespace')

      expect(connection)
        .to have_received(:signal_workflow_execution)
        .with(
          namespace: 'other-test-namespace',
          signal: 'signal', 
          workflow_id: 'workflow_id',
          run_id: 'run_id',
          input: nil,
        )
    end
  end

  describe '#await_workflow_result' do
    class NamespacedWorkflow < Temporal::Workflow
      namespace 'some-namespace'
      task_queue 'some-task-queue'
    end

    let(:workflow_id) {'dummy_worklfow_id'}
    let(:run_id) {'dummy_run_id'}

    it 'looks up history in the correct namespace for namespaced workflows' do
      completed_event = Fabricate(:workflow_completed_event, result: nil)
      response = Fabricate(:workflow_execution_history, events: [completed_event])

      expect(connection)
        .to receive(:get_workflow_execution_history)
        .with(
          namespace: 'some-namespace',
          workflow_id: workflow_id,
          run_id: run_id,
          wait_for_new_event: true,
          event_type: :close,
          timeout: 30,
        )
        .and_return(response)

        subject.await_workflow_result(
        NamespacedWorkflow,
        workflow_id: workflow_id,
        run_id: run_id,
      )
    end

    it 'retries if there is till there is no closed event' do
      completed_event = Fabricate(:workflow_completed_event, result: nil)
      response_with_no_closed_event = Fabricate(:workflow_execution_history, events: [])
      response_with_closed_event = Fabricate(:workflow_execution_history, events: [completed_event])

      expect(connection)
        .to receive(:get_workflow_execution_history)
        .with(
          namespace: 'some-namespace',
          workflow_id: workflow_id,
          run_id: run_id,
          wait_for_new_event: true,
          event_type: :close,
          timeout: 30,
        )
        .and_return(response_with_no_closed_event, response_with_closed_event)


        subject.await_workflow_result(
        NamespacedWorkflow,
        workflow_id: workflow_id,
        run_id: run_id,
      )
    end

    it 'can override the namespace' do 
      completed_event = Fabricate(:workflow_completed_event, result: nil)
      response = Fabricate(:workflow_execution_history, events: [completed_event])

      expect(connection)
        .to receive(:get_workflow_execution_history)
        .with(
          namespace: 'some-other-namespace',
          workflow_id: workflow_id,
          run_id: run_id,
          wait_for_new_event: true,
          event_type: :close,
          timeout: 30,
        )
        .and_return(response)

        subject.await_workflow_result(
        NamespacedWorkflow,
        workflow_id: workflow_id,
        run_id: run_id,
        namespace: 'some-other-namespace'
      )
    end

    [
      ['hash', { 'key' => 'value' }],
      ['integer', 5],
      ['nil', nil],
      ['string', 'a result'],
    ].each do |(type, expected_result)|
      it "completes and returns a #{type}" do
        payload = Temporalio::Api::Common::V1::Payloads.new(
          payloads: [
            Temporal.configuration.converter.to_payload(expected_result)
          ],
        )
        completed_event = Fabricate(:workflow_completed_event, result: payload)
        response = Fabricate(:workflow_execution_history, events: [completed_event])
        expect(connection)
          .to receive(:get_workflow_execution_history)
          .with(
            namespace: 'default-test-namespace',
            workflow_id: workflow_id,
            run_id: nil,
            wait_for_new_event: true,
            event_type: :close,
            timeout: 30,
          )
          .and_return(response)

        actual_result = subject.await_workflow_result(
          TestStartWorkflow,
          workflow_id: workflow_id,
        )
        expect(actual_result).to eq(expected_result)
      end
    end

    # Unit test, rather than integration test, because we don't support cancellation via the SDK yet.
    # See integration test for other failure conditions.
    it 'raises when the workflow was canceled' do
      completed_event = Fabricate(:workflow_canceled_event)
      response = Fabricate(:workflow_execution_history, events: [completed_event])

      expect(connection)
        .to receive(:get_workflow_execution_history)
        .with(
          namespace: 'default-test-namespace',
          workflow_id: workflow_id,
          run_id: run_id,
          wait_for_new_event: true,
          event_type: :close,
          timeout: 30,
        )
        .and_return(response)

      expect do
        subject.await_workflow_result(
          TestStartWorkflow,
          workflow_id: workflow_id,
          run_id: run_id,
        )
      end.to raise_error(Temporal::WorkflowCanceled)
    end

    it 'raises TimeoutError when the server times out' do 
      response = Fabricate(:workflow_execution_history, events: [])
      expect(connection)
        .to receive(:get_workflow_execution_history)
        .with(
          namespace: 'default-test-namespace',
          workflow_id: workflow_id,
          run_id: run_id,
          wait_for_new_event: true,
          event_type: :close,
          timeout: 3,
        )
        .and_raise(GRPC::DeadlineExceeded)
        expect do
          subject.await_workflow_result(
            TestStartWorkflow,
            workflow_id: workflow_id,
            run_id: run_id,
            timeout: 3,
          )
        end.to raise_error(Temporal::TimeoutError)
    end
  end

  describe '#reset_workflow' do
    let(:temporal_response) do
      Temporalio::Api::WorkflowService::V1::ResetWorkflowExecutionResponse.new(run_id: 'xxx')
    end
    let(:history) do
      Temporal::Workflow::History.new([
        Fabricate(:api_workflow_execution_started_event, event_id: 1),
        Fabricate(:api_workflow_task_scheduled_event, event_id: 2),
        Fabricate(:api_workflow_task_started_event, event_id: 3),
        Fabricate(:api_workflow_task_completed_event, event_id: 4),
        Fabricate(:api_activity_task_scheduled_event, event_id: 5),
        Fabricate(:api_activity_task_started_event, event_id: 6),
        Fabricate(:api_activity_task_completed_event, event_id: 7),
        Fabricate(:api_workflow_task_scheduled_event, event_id: 8),
        Fabricate(:api_workflow_task_started_event, event_id: 9),
        Fabricate(:api_workflow_task_completed_event, event_id: 10),
        Fabricate(:api_activity_task_scheduled_event, event_id: 11),
        Fabricate(:api_activity_task_started_event, event_id: 12),
        Fabricate(:api_activity_task_failed_event, event_id: 13),
        Fabricate(:api_workflow_task_scheduled_event, event_id: 14),
        Fabricate(:api_workflow_task_started_event, event_id: 15),
        Fabricate(:api_workflow_task_completed_event, event_id: 16),
        Fabricate(:api_workflow_execution_completed_event, event_id: 17)
      ])
    end

    before { allow(connection).to receive(:reset_workflow_execution).and_return(temporal_response) }

    before do
      allow(connection).to receive(:reset_workflow_execution).and_return(temporal_response)
      allow(subject)
        .to receive(:get_workflow_history)
        .with(namespace: namespace, workflow_id: workflow_id, run_id: run_id)
        .and_return(history)
    end

    context 'when workflow_task_id is provided' do
      let(:workflow_task_id) { 42 }

      it 'calls connection reset_workflow_execution' do
        subject.reset_workflow(
          'default-test-namespace',
          '123',
          '1234',
          workflow_task_id: workflow_task_id,
          reason: 'Test reset'
        )

        expect(connection).to have_received(:reset_workflow_execution).with(
          namespace: 'default-test-namespace',
          workflow_id: '123',
          run_id: '1234',
          reason: 'Test reset',
          workflow_task_event_id: workflow_task_id,
          # The request ID will be a random UUID:
          request_id: anything,
          reset_reapply_type: :signal
        )
      end

      it 'passes through request_id and reset_reapply_type' do
        subject.reset_workflow(
          'default-test-namespace',
          '123',
          '1234',
          workflow_task_id: workflow_task_id,
          reason: 'Test reset',
          request_id: 'foo',
          reset_reapply_type: Temporal::ResetReapplyType::SIGNAL
        )

        expect(connection).to have_received(:reset_workflow_execution).with(
          namespace: 'default-test-namespace',
          workflow_id: '123',
          run_id: '1234',
          reason: 'Test reset',
          workflow_task_event_id: workflow_task_id,
          request_id: 'foo',
          reset_reapply_type: :signal
        )
      end

      it 'returns the new run_id' do
        result = subject.reset_workflow(
          'default-test-namespace',
          '123',
          '1234',
          workflow_task_id: workflow_task_id
        )

        expect(result).to eq('xxx')
      end
    end

    context 'when neither strategy nor workflow_task_id is provided' do
      it 'uses default strategy' do
        subject.reset_workflow(namespace, workflow_id, run_id)

        expect(connection).to have_received(:reset_workflow_execution).with(
          namespace: namespace,
          workflow_id: workflow_id,
          run_id: run_id,
          reason: 'manual reset',
          workflow_task_event_id: 16,
          # The request ID will be a random UUID:
          request_id: instance_of(String),
          reset_reapply_type: :signal
        )
      end
    end

    context 'when both strategy and workflow_task_id are provided' do
      it 'uses default strategy' do
        expect do
          subject.reset_workflow(
            namespace,
            workflow_id,
            run_id,
            strategy: :last_workflow_task,
            workflow_task_id: 10
          )
        end.to raise_error(ArgumentError, 'Please specify either :strategy or :workflow_task_id')
      end
    end

    context 'with a specified strategy' do
      context ':last_workflow_task' do
        it 'resets workflow' do
          subject.reset_workflow(namespace, workflow_id, run_id, strategy: :last_workflow_task)

          expect(connection).to have_received(:reset_workflow_execution).with(
            namespace: namespace,
            workflow_id: workflow_id,
            run_id: run_id,
            reason: 'manual reset',
            workflow_task_event_id: 16,
            # The request ID will be a random UUID:
            request_id: instance_of(String),
            reset_reapply_type: :signal
          )
        end
      end

      context ':first_workflow_task' do
        it 'resets workflow' do
          subject.reset_workflow(namespace, workflow_id, run_id, strategy: :first_workflow_task)

          expect(connection).to have_received(:reset_workflow_execution).with(
            namespace: namespace,
            workflow_id: workflow_id,
            run_id: run_id,
            reason: 'manual reset',
            workflow_task_event_id: 4,
            # The request ID will be a random UUID:
            request_id: instance_of(String),
            reset_reapply_type: :signal
          )
        end
      end


      context ':last_failed_activity' do
        it 'resets workflow' do
          subject.reset_workflow(namespace, workflow_id, run_id, strategy: :last_failed_activity)

          expect(connection).to have_received(:reset_workflow_execution).with(
            namespace: namespace,
            workflow_id: workflow_id,
            run_id: run_id,
            reason: 'manual reset',
            workflow_task_event_id: 10,
            # The request ID will be a random UUID:
            request_id: instance_of(String),
            reset_reapply_type: :signal
          )
        end
      end

      context 'unsupported strategy' do
        it 'resets workflow' do
          expect do
            subject.reset_workflow(namespace, workflow_id, run_id, strategy: :foobar)
          end.to raise_error(ArgumentError, 'Unsupported reset strategy')
        end
      end
    end
  end

  describe '#terminate_workflow' do
    let(:temporal_response) do
      Temporalio::Api::WorkflowService::V1::TerminateWorkflowExecutionResponse.new
    end

    before { allow(connection).to receive(:terminate_workflow_execution).and_return(temporal_response) }

    it 'terminates a workflow' do
      subject.terminate_workflow('my-workflow', reason: 'just stop it')

      expect(connection)
        .to have_received(:terminate_workflow_execution)
        .with(
          namespace: 'default-namespace',
          workflow_id: 'my-workflow',
          reason: 'just stop it',
          details: nil,
          run_id: nil
        )
    end
  end

  describe '#fetch_workflow_execution_info' do
    let(:response) do
      Temporalio::Api::WorkflowService::V1::DescribeWorkflowExecutionResponse.new(
        workflow_execution_info: api_info
      )
    end
    let(:api_info) { Fabricate(:api_workflow_execution_info, workflow: 'TestWorkflow', workflow_id: '') }

    before { allow(connection).to receive(:describe_workflow_execution).and_return(response) }

    it 'requests execution info from Temporal' do
      subject.fetch_workflow_execution_info('namespace', '111', '222')

      expect(connection)
        .to have_received(:describe_workflow_execution)
        .with(namespace: 'namespace', workflow_id: '111', run_id: '222')
    end

    it 'returns Workflow::ExecutionInfo' do
      info = subject.fetch_workflow_execution_info('namespace', '111', '222')

      expect(info).to be_a(Temporal::Workflow::ExecutionInfo)
    end
  end

  context 'activity operations' do
    let(:namespace) { 'test-namespace' }
    let(:activity_id) { rand(100).to_s }
    let(:workflow_id) { SecureRandom.uuid }
    let(:run_id) { SecureRandom.uuid }
    let(:async_token) do
      Temporal::Activity::AsyncToken.encode(namespace, activity_id, workflow_id, run_id)
    end

    describe '#complete_activity' do
      before { allow(connection).to receive(:respond_activity_task_completed_by_id).and_return(nil) }

      it 'completes activity with a result' do
        subject.complete_activity(async_token, 'all work completed')

        expect(connection)
          .to have_received(:respond_activity_task_completed_by_id)
          .with(
            namespace: namespace,
            activity_id: activity_id,
            workflow_id: workflow_id,
            run_id: run_id,
            result: 'all work completed'
          )
      end

      it 'completes activity without a result' do
        subject.complete_activity(async_token)

        expect(connection)
          .to have_received(:respond_activity_task_completed_by_id)
          .with(
            namespace: namespace,
            activity_id: activity_id,
            workflow_id: workflow_id,
            run_id: run_id,
            result: nil
          )
      end
    end

    describe '#fail_activity' do
      before { allow(connection).to receive(:respond_activity_task_failed_by_id).and_return(nil) }

      it 'fails activity with a provided error' do
        exception = StandardError.new('something went wrong')
        subject.fail_activity(async_token, exception)

        expect(connection)
          .to have_received(:respond_activity_task_failed_by_id)
          .with(
            namespace: namespace,
            activity_id: activity_id,
            workflow_id: workflow_id,
            run_id: run_id,
            exception: exception
          )
      end
    end
  end

  describe '#add_custom_search_attributes' do
    before { allow(connection).to receive(:add_custom_search_attributes) }

    let(:attributes) { { SomeTextField: :text, SomeIntField: :int } }

    it 'passes through to connection' do
      subject.add_custom_search_attributes(attributes)

      expect(connection)
        .to have_received(:add_custom_search_attributes)
        .with(attributes, namespace)
    end
  end

  describe '#list_custom_search_attributes' do
    let(:attributes) { { 'SomeIntField' => :int, 'SomeBoolField' => :bool } }

    before { allow(connection).to receive(:list_custom_search_attributes).and_return(attributes) }

    it 'passes through to connection' do
      response = subject.list_custom_search_attributes

      expect(response).to eq(attributes)

      expect(connection)
        .to have_received(:list_custom_search_attributes)
    end
  end

  describe '#remove_custom_search_attributes' do
    before { allow(connection).to receive(:remove_custom_search_attributes) }

    it 'passes through to connection' do
      subject.remove_custom_search_attributes(:SomeTextField, :SomeIntField)

      expect(connection)
        .to have_received(:remove_custom_search_attributes)
        .with(%i[SomeTextField SomeIntField], namespace)
    end
  end

  describe '#list_open_workflow_executions' do
    let(:from) { Time.now - 600 }
    let(:now) { Time.now }
    let(:api_execution_info) do
      Fabricate(:api_workflow_execution_info, workflow: 'TestWorkflow', workflow_id: '')
    end
    let(:response) do
      Temporalio::Api::WorkflowService::V1::ListOpenWorkflowExecutionsResponse.new(
        executions: [api_execution_info],
        next_page_token: ''
      )
    end

    before do
      allow(Time).to receive(:now).and_return(now)
      allow(connection)
        .to receive(:list_open_workflow_executions)
        .and_return(response)
    end

    it 'returns a list of executions' do
      executions = subject.list_open_workflow_executions(namespace, from)
      expect(executions.count).to eq(1)
      expect(executions.first).to be_an_instance_of(Temporal::Workflow::ExecutionInfo)
    end

    context 'when history is paginated' do
      let(:response_1) do
        Temporalio::Api::WorkflowService::V1::ListOpenWorkflowExecutionsResponse.new(
          executions: [api_execution_info],
          next_page_token: 'a'
        )
      end
      let(:response_2) do
        Temporalio::Api::WorkflowService::V1::ListOpenWorkflowExecutionsResponse.new(
          executions: [api_execution_info],
          next_page_token: 'b'
        )
      end
      let(:response_3) do
        Temporalio::Api::WorkflowService::V1::ListOpenWorkflowExecutionsResponse.new(
          executions: [api_execution_info],
          next_page_token: ''
        )
      end

      before do
        allow(connection)
          .to receive(:list_open_workflow_executions)
          .and_return(response_1, response_2, response_3)
      end

      it 'calls the API 3 times' do
        subject.list_open_workflow_executions(namespace, from).count

        expect(connection).to have_received(:list_open_workflow_executions).exactly(3).times

        expect(connection)
          .to have_received(:list_open_workflow_executions)
          .with(namespace: namespace, from: from, to: now, next_page_token: nil, max_page_size: nil)
          .once

        expect(connection)
          .to have_received(:list_open_workflow_executions)
          .with(namespace: namespace, from: from, to: now, next_page_token: 'a', max_page_size: nil)
          .once

        expect(connection)
          .to have_received(:list_open_workflow_executions)
          .with(namespace: namespace, from: from, to: now, next_page_token: 'b', max_page_size: nil)
          .once
      end

      it 'returns a list of executions' do
        executions = subject.list_open_workflow_executions(namespace, from)

        expect(executions.count).to eq(3)
        executions.each do |execution|
          expect(execution).to be_an_instance_of(Temporal::Workflow::ExecutionInfo)
        end
      end

      it 'returns the next page token and paginates correctly' do        
        executions1 = subject.list_open_workflow_executions(namespace, from, max_page_size: 10)
        executions1.map do |execution|
          expect(execution).to be_an_instance_of(Temporal::Workflow::ExecutionInfo)
        end
        expect(executions1.next_page_token).to eq('a')
        expect(connection)
          .to have_received(:list_open_workflow_executions)
          .with(namespace: namespace, from: from, to: now, next_page_token: nil, max_page_size: 10)
          .once

        executions2 = subject.list_open_workflow_executions(namespace, from, next_page_token: executions1.next_page_token, max_page_size: 10)
        executions2.map do |execution|
          expect(execution).to be_an_instance_of(Temporal::Workflow::ExecutionInfo)
        end
        expect(executions2.next_page_token).to eq('b')
        expect(connection)
          .to have_received(:list_open_workflow_executions)
          .with(namespace: namespace, from: from, to: now, next_page_token: 'a', max_page_size: 10)
          .once

        executions3 = subject.list_open_workflow_executions(namespace, from, next_page_token: executions2.next_page_token, max_page_size: 10)
        executions3.map do |execution|
          expect(execution).to be_an_instance_of(Temporal::Workflow::ExecutionInfo)
        end
        expect(executions3.next_page_token).to eq('')
        expect(connection)
          .to have_received(:list_open_workflow_executions)
          .with(namespace: namespace, from: from, to: now, next_page_token: 'a', max_page_size: 10)
          .once
      end

      it 'returns the next page and paginates correctly' do        
        executions1 = subject.list_open_workflow_executions(namespace, from, max_page_size: 10)
        executions1.map do |execution|
          expect(execution).to be_an_instance_of(Temporal::Workflow::ExecutionInfo)
        end
        expect(executions1.next_page_token).to eq('a')
        expect(connection)
          .to have_received(:list_open_workflow_executions)
          .with(namespace: namespace, from: from, to: now, next_page_token: nil, max_page_size: 10)
          .once

        executions2 = executions1.next_page
        executions2.map do |execution|
          expect(execution).to be_an_instance_of(Temporal::Workflow::ExecutionInfo)
        end
        expect(executions2.next_page_token).to eq('b')
        expect(connection)
          .to have_received(:list_open_workflow_executions)
          .with(namespace: namespace, from: from, to: now, next_page_token: 'a', max_page_size: 10)
          .once

        executions3 = executions2.next_page
        executions3.map do |execution|
          expect(execution).to be_an_instance_of(Temporal::Workflow::ExecutionInfo)
        end
        expect(executions3.next_page_token).to eq('')
        expect(connection)
          .to have_received(:list_open_workflow_executions)
          .with(namespace: namespace, from: from, to: now, next_page_token: 'a', max_page_size: 10)
          .once
      end
    end

    context 'when given unsupported filter' do
      let(:filter) { { foo: :bar } }

      it 'raises ArgumentError' do
        expect do
          subject.list_open_workflow_executions(namespace, from, filter: filter).to_a
        end.to raise_error(ArgumentError, 'Allowed filters are: [:workflow, :workflow_id]')
      end
    end

    context 'when given multiple filters' do
      let(:filter) { { workflow: 'TestWorkflow', workflow_id: 'xxx' } }

      it 'raises ArgumentError' do
        expect do
          subject.list_open_workflow_executions(namespace, from, filter: filter).count
        end.to raise_error(ArgumentError, 'Only one filter is allowed')
      end
    end

    context 'when called without filters' do
      it 'makes a request' do
        subject.list_open_workflow_executions(namespace, from).to_a

        expect(connection)
          .to have_received(:list_open_workflow_executions)
          .with(namespace: namespace, from: from, to: now, next_page_token: nil, max_page_size: nil)
      end
    end

    context 'when called with :to' do
      it 'makes a request' do
        subject.list_open_workflow_executions(namespace, from, now - 10).to_a

        expect(connection)
          .to have_received(:list_open_workflow_executions)
          .with(namespace: namespace, from: from, to: now - 10, next_page_token: nil, max_page_size: nil)
      end
    end

    context 'when called with a :workflow filter' do
      it 'makes a request' do
        subject.list_open_workflow_executions(namespace, from, filter: { workflow: 'TestWorkflow' }).to_a

        expect(connection)
          .to have_received(:list_open_workflow_executions)
          .with(namespace: namespace, from: from, to: now, next_page_token: nil, workflow: 'TestWorkflow', max_page_size: nil)
      end
    end

    context 'when called with a :workflow_id filter' do
      it 'makes a request' do
        subject.list_open_workflow_executions(namespace, from, filter: { workflow_id: 'xxx' }).to_a

        expect(connection)
          .to have_received(:list_open_workflow_executions)
          .with(namespace: namespace, from: from, to: now, next_page_token: nil, workflow_id: 'xxx', max_page_size: nil)
      end
    end
  end

  describe '#count_workflow_executions' do
    let(:response) do
      Temporalio::Api::WorkflowService::V1::CountWorkflowExecutionsResponse.new(
        count: 5
      )
    end

    before do
      allow(connection)
        .to receive(:count_workflow_executions)
        .and_return(response)
    end

    it 'returns the count' do
      resp = subject.count_workflow_executions(namespace, query: 'ExecutionStatus="Running"')

      expect(connection)
        .to have_received(:count_workflow_executions)
        .with(namespace: namespace, query: 'ExecutionStatus="Running"')

      expect(resp).to eq(5)
    end
  end
end
