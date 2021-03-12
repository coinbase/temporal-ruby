require 'temporal'
require 'temporal/workflow'

describe Temporal do
  describe 'client operations' do
    let(:client) { instance_double(Temporal::Client::GRPCClient) }

    class TestStartWorkflow < Temporal::Workflow
      namespace 'default-test-namespace'
      task_queue 'default-test-task-queue'
    end

    before { allow(Temporal::Client).to receive(:generate).and_return(client) }
    after { described_class.remove_instance_variable(:@client) rescue NameError }

    describe '.start_workflow' do
      let(:temporal_response) do
        Temporal::Api::WorkflowService::V1::StartWorkflowExecutionResponse.new(run_id: 'xxx')
      end

      before { allow(client).to receive(:start_workflow_execution).and_return(temporal_response) }

      context 'using a workflow class' do
        it 'returns run_id' do
          result = described_class.start_workflow(TestStartWorkflow, 42)

          expect(result).to eq(temporal_response.run_id)
        end

        it 'starts a workflow using the default options' do
          described_class.start_workflow(TestStartWorkflow, 42)

          expect(client)
            .to have_received(:start_workflow_execution)
            .with(
              namespace: 'default-test-namespace',
              workflow_id: an_instance_of(String),
              workflow_name: 'TestStartWorkflow',
              task_queue: 'default-test-task-queue',
              input: [42],
              task_timeout: Temporal.configuration.timeouts[:task],
              execution_timeout: Temporal.configuration.timeouts[:execution],
              workflow_id_reuse_policy: nil,
              headers: {}
            )
        end

        it 'starts a workflow using the options specified' do
          described_class.start_workflow(
            TestStartWorkflow,
            42,
            options: {
              name: 'test-workflow',
              namespace: 'test-namespace',
              task_queue: 'test-task-queue',
              headers: { 'Foo' => 'Bar' }
            }
          )

          expect(client)
            .to have_received(:start_workflow_execution)
            .with(
              namespace: 'test-namespace',
              workflow_id: an_instance_of(String),
              workflow_name: 'test-workflow',
              task_queue: 'test-task-queue',
              input: [42],
              task_timeout: Temporal.configuration.timeouts[:task],
              execution_timeout: Temporal.configuration.timeouts[:execution],
              workflow_id_reuse_policy: nil,
              headers: { 'Foo' => 'Bar' }
            )
        end

        it 'starts a workflow using a mix of input, keyword arguments and options' do
          described_class.start_workflow(
            TestStartWorkflow,
            42,
            arg_1: 1,
            arg_2: 2,
            options: { name: 'test-workflow' }
          )

          expect(client)
            .to have_received(:start_workflow_execution)
            .with(
              namespace: 'default-test-namespace',
              workflow_id: an_instance_of(String),
              workflow_name: 'test-workflow',
              task_queue: 'default-test-task-queue',
              input: [42, { arg_1: 1, arg_2: 2 }],
              task_timeout: Temporal.configuration.timeouts[:task],
              execution_timeout: Temporal.configuration.timeouts[:execution],
              workflow_id_reuse_policy: nil,
              headers: {}
            )
        end

        it 'starts a workflow using specified workflow_id' do
          described_class.start_workflow(TestStartWorkflow, 42, options: { workflow_id: '123' })

          expect(client)
            .to have_received(:start_workflow_execution)
            .with(
              namespace: 'default-test-namespace',
              workflow_id: '123',
              workflow_name: 'TestStartWorkflow',
              task_queue: 'default-test-task-queue',
              input: [42],
              task_timeout: Temporal.configuration.timeouts[:task],
              execution_timeout: Temporal.configuration.timeouts[:execution],
              workflow_id_reuse_policy: nil,
              headers: {}
            )
        end

        it 'starts a workflow with a workflow id reuse policy' do
          described_class.start_workflow(
            TestStartWorkflow, 42, options: { workflow_id_reuse_policy: :allow }
          )

          expect(client)
            .to have_received(:start_workflow_execution)
            .with(
              namespace: 'default-test-namespace',
              workflow_id: an_instance_of(String),
              workflow_name: 'TestStartWorkflow',
              task_queue: 'default-test-task-queue',
              input: [42],
              task_timeout: Temporal.configuration.timeouts[:task],
              execution_timeout: Temporal.configuration.timeouts[:execution],
              workflow_id_reuse_policy: :allow,
              headers: {}
            )
        end
      end

      context 'using a string reference' do
        it 'starts a workflow' do
          described_class.start_workflow(
            'test-workflow',
            42,
            options: { namespace: 'test-namespace', task_queue: 'test-task-queue' }
          )

          expect(client)
            .to have_received(:start_workflow_execution)
            .with(
              namespace: 'test-namespace',
              workflow_id: an_instance_of(String),
              workflow_name: 'test-workflow',
              task_queue: 'test-task-queue',
              input: [42],
              task_timeout: Temporal.configuration.timeouts[:task],
              execution_timeout: Temporal.configuration.timeouts[:execution],
              workflow_id_reuse_policy: nil,
              headers: {}
            )
        end
      end
    end

    describe '.terminate_workflow' do
      let(:temporal_response) do
        Temporal::Api::WorkflowService::V1::TerminateWorkflowExecutionResponse.new
      end

      before { allow(client).to receive(:terminate_workflow_execution).and_return(temporal_response) }

      it 'terminates a workflow' do
        described_class.terminate_workflow(TestStartWorkflow, workflow_id: 'my-workflow', reason: 'just stop it')

        expect(client)
          .to have_received(:terminate_workflow_execution)
          .with(
            namespace: 'default-test-namespace',
            workflow_id: 'my-workflow',
            reason: 'just stop it',
            details: nil,
            run_id: nil
          )
      end
    end

    describe '.schedule_workflow' do
      let(:temporal_response) do
        Temporal::Api::WorkflowService::V1::StartWorkflowExecutionResponse.new(run_id: 'xxx')
      end

      before { allow(client).to receive(:start_workflow_execution).and_return(temporal_response) }

      it 'starts a cron workflow' do
        described_class.schedule_workflow(TestStartWorkflow, '* * * * *', 42)

        expect(client)
          .to have_received(:start_workflow_execution)
          .with(
            namespace: 'default-test-namespace',
            workflow_id: an_instance_of(String),
            workflow_name: 'TestStartWorkflow',
            task_queue: 'default-test-task-queue',
            cron_schedule: '* * * * *',
            input: [42],
            task_timeout: Temporal.configuration.timeouts[:task],
            execution_timeout: Temporal.configuration.timeouts[:execution],
            workflow_id_reuse_policy: nil,
            headers: {}
          )
      end
    end

    describe '.register_namespace' do
      before { allow(client).to receive(:register_namespace).and_return(nil) }

      it 'registers namespace with the specified name' do
        described_class.register_namespace('new-namespace')

        expect(client)
          .to have_received(:register_namespace)
          .with(name: 'new-namespace', description: nil)
      end

      it 'registers namespace with the specified name and description' do
        described_class.register_namespace('new-namespace', 'namespace description')

        expect(client)
          .to have_received(:register_namespace)
          .with(name: 'new-namespace', description: 'namespace description')
      end
    end

    describe '.fetch_workflow_execution_info' do
      let(:response) do
        Temporal::Api::WorkflowService::V1::DescribeWorkflowExecutionResponse.new(
          workflow_execution_info: api_info
        )
      end
      let(:api_info) { Fabricate(:api_workflow_execution_info) }

      before { allow(client).to receive(:describe_workflow_execution).and_return(response) }

      it 'requests execution info from Temporal' do
        described_class.fetch_workflow_execution_info('namespace', '111', '222')

        expect(client)
          .to have_received(:describe_workflow_execution)
          .with(namespace: 'namespace', workflow_id: '111', run_id: '222')
      end

      it 'returns Workflow::ExecutionInfo' do
        info = described_class.fetch_workflow_execution_info('namespace', '111', '222')

        expect(info).to be_a(Temporal::Workflow::ExecutionInfo)
      end
    end

    describe '.reset_workflow' do
      let(:temporal_response) do
        Temporal::Api::WorkflowService::V1::ResetWorkflowExecutionResponse.new(run_id: 'xxx')
      end

      before { allow(client).to receive(:reset_workflow_execution).and_return(temporal_response) }

      context 'when workflow_task_id is provided' do
        let(:workflow_task_id) { 42 }

        it 'calls client reset_workflow_execution' do
          described_class.reset_workflow(
            'default-test-namespace',
            '123',
            '1234',
            workflow_task_id: workflow_task_id,
            reason: 'Test reset'
          )

          expect(client).to have_received(:reset_workflow_execution).with(
            namespace: 'default-test-namespace',
            workflow_id: '123',
            run_id: '1234',
            reason: 'Test reset',
            workflow_task_event_id: workflow_task_id
          )
        end

        it 'returns the new run_id' do
          result = described_class.reset_workflow(
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

      describe '.complete_activity' do
        before { allow(client).to receive(:respond_activity_task_completed_by_id).and_return(nil) }

        it 'completes activity with a result' do
          described_class.complete_activity(async_token, 'all work completed')

          expect(client)
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
          described_class.complete_activity(async_token)

          expect(client)
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

      describe '.fail_activity' do
        before { allow(client).to receive(:respond_activity_task_failed_by_id).and_return(nil) }

        it 'fails activity with a provided error' do
          exception = StandardError.new('something went wrong')
          described_class.fail_activity(async_token, exception)

          expect(client)
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

  describe '.configure' do
    it 'calls a block with the configuration' do
      expect do |block|
        described_class.configure(&block)
      end.to yield_with_args(described_class.configuration)
    end
  end

  describe '.configuration' do
    it 'returns Temporal::Configuration object' do
      expect(described_class.configuration).to be_an_instance_of(Temporal::Configuration)
    end
  end

  describe '.logger' do
    it 'returns preconfigured Temporal logger' do
      expect(described_class.logger).to eq(described_class.configuration.logger)
    end
  end
end
