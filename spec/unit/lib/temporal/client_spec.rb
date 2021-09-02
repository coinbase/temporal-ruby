require 'temporal/client'
require 'temporal/configuration'
require 'temporal/workflow'
require 'temporal/connection/grpc'

describe Temporal::Client do
  subject { described_class.new(config) }

  let(:config) { Temporal::Configuration.new }
  let(:connection) { instance_double(Temporal::Connection::GRPC) }

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
  after { subject.remove_instance_variable(:@connection) }

  describe '#start_workflow' do
    let(:temporal_response) do
      Temporal::Api::WorkflowService::V1::StartWorkflowExecutionResponse.new(run_id: 'xxx')
    end

    before { allow(connection).to receive(:start_workflow_execution).and_return(temporal_response) }

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
            headers: {}
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
            headers: { 'Foo' => 'Bar' }
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
            workflow_id_reuse_policy: nil,
            headers: { 'Foo' => 'Bar' }
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
            headers: {}
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
            headers: {}
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
            headers: {}
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
            headers: {}
          )
      end
    end
  end

  describe '#schedule_workflow' do
    let(:temporal_response) do
      Temporal::Api::WorkflowService::V1::StartWorkflowExecutionResponse.new(run_id: 'xxx')
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
          headers: {}
        )
    end
  end

  describe '#terminate_workflow' do
    let(:temporal_response) do
      Temporal::Api::WorkflowService::V1::TerminateWorkflowExecutionResponse.new
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

  describe '#register_namespace' do
    before { allow(connection).to receive(:register_namespace).and_return(nil) }

    it 'registers namespace with the specified name' do
      subject.register_namespace('new-namespace')

      expect(connection)
        .to have_received(:register_namespace)
        .with(name: 'new-namespace', description: nil)
    end

    it 'registers namespace with the specified name and description' do
      subject.register_namespace('new-namespace', 'namespace description')

      expect(connection)
        .to have_received(:register_namespace)
        .with(name: 'new-namespace', description: 'namespace description')
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
      {type: 'hash', expected_result: { 'key' => 'value' }},
      {type: 'integer', expected_result: 5},
      {type: 'nil', expected_result: nil},
      {type: 'string', expected_result: 'a result'},
    ].each do |type:, expected_result:|
      it "completes and returns a #{type}" do
        payload = Temporal::Api::Common::V1::Payloads.new(
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

  describe '#fetch_workflow_execution_info' do
    let(:response) do
      Temporal::Api::WorkflowService::V1::DescribeWorkflowExecutionResponse.new(
        workflow_execution_info: api_info
      )
    end
    let(:api_info) { Fabricate(:api_workflow_execution_info) }

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

  describe '#reset_workflow' do
    let(:temporal_response) do
      Temporal::Api::WorkflowService::V1::ResetWorkflowExecutionResponse.new(run_id: 'xxx')
    end

    before { allow(connection).to receive(:reset_workflow_execution).and_return(temporal_response) }

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
          workflow_task_event_id: workflow_task_id
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
end
