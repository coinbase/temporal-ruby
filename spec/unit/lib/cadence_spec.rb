require 'cadence'
require 'cadence/workflow'

describe Cadence do
  describe 'client operations' do
    let(:client) { instance_double(Cadence::Client::ThriftClient) }

    before { allow(Cadence::Client).to receive(:generate).and_return(client) }
    after { described_class.remove_instance_variable(:@client) }

    describe '.start_workflow' do
      let(:cadence_response) do
        CadenceThrift::StartWorkflowExecutionResponse.new(runId: 'xxx')
      end

      before { allow(client).to receive(:start_workflow_execution).and_return(cadence_response) }

      context 'using a workflow class' do
        class TestStartWorkflow < Cadence::Workflow
          domain 'default-test-domain'
          task_list 'default-test-task-list'
        end

        it 'returns run_id' do
          result = described_class.start_workflow(TestStartWorkflow, 42)

          expect(result).to eq(cadence_response.runId)
        end

        it 'starts a workflow using the default options' do
          described_class.start_workflow(TestStartWorkflow, 42)

          expect(client)
            .to have_received(:start_workflow_execution)
            .with(
              domain: 'default-test-domain',
              workflow_id: an_instance_of(String),
              workflow_name: 'TestStartWorkflow',
              task_list: 'default-test-task-list',
              input: [42],
              task_timeout: Cadence.configuration.timeouts[:task],
              execution_timeout: Cadence.configuration.timeouts[:execution],
              workflow_id_reuse_policy: nil
            )
        end

        it 'starts a workflow using the options specified' do
          described_class.start_workflow(
            TestStartWorkflow,
            42,
            options: { name: 'test-workflow', domain: 'test-domain', task_list: 'test-task-list' }
          )

          expect(client)
            .to have_received(:start_workflow_execution)
            .with(
              domain: 'test-domain',
              workflow_id: an_instance_of(String),
              workflow_name: 'test-workflow',
              task_list: 'test-task-list',
              input: [42],
              task_timeout: Cadence.configuration.timeouts[:task],
              execution_timeout: Cadence.configuration.timeouts[:execution],
              workflow_id_reuse_policy: nil
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
              domain: 'default-test-domain',
              workflow_id: an_instance_of(String),
              workflow_name: 'test-workflow',
              task_list: 'default-test-task-list',
              input: [42, { arg_1: 1, arg_2: 2 }],
              task_timeout: Cadence.configuration.timeouts[:task],
              execution_timeout: Cadence.configuration.timeouts[:execution],
              workflow_id_reuse_policy: nil
            )
        end

        it 'starts a workflow using specified workflow_id' do
          described_class.start_workflow(TestStartWorkflow, 42, options: { workflow_id: '123' })

          expect(client)
            .to have_received(:start_workflow_execution)
            .with(
              domain: 'default-test-domain',
              workflow_id: '123',
              workflow_name: 'TestStartWorkflow',
              task_list: 'default-test-task-list',
              input: [42],
              task_timeout: Cadence.configuration.timeouts[:task],
              execution_timeout: Cadence.configuration.timeouts[:execution],
              workflow_id_reuse_policy: nil
            )
        end

        it 'starts a workflow with a workflow id reuse policy' do
          described_class.start_workflow(
            TestStartWorkflow, 42, options: { workflow_id_reuse_policy: :allow }
          )

          expect(client)
            .to have_received(:start_workflow_execution)
            .with(
              domain: 'default-test-domain',
              workflow_id: an_instance_of(String),
              workflow_name: 'TestStartWorkflow',
              task_list: 'default-test-task-list',
              input: [42],
              task_timeout: Cadence.configuration.timeouts[:task],
              execution_timeout: Cadence.configuration.timeouts[:execution],
              workflow_id_reuse_policy: :allow
            )
        end
      end

      context 'using a string reference' do
        it 'starts a workflow' do
          described_class.start_workflow(
            'test-workflow',
            42,
            options: { domain: 'test-domain', task_list: 'test-task-list' }
          )

          expect(client)
            .to have_received(:start_workflow_execution)
            .with(
              domain: 'test-domain',
              workflow_id: an_instance_of(String),
              workflow_name: 'test-workflow',
              task_list: 'test-task-list',
              input: [42],
              task_timeout: Cadence.configuration.timeouts[:task],
              execution_timeout: Cadence.configuration.timeouts[:execution],
              workflow_id_reuse_policy: nil
            )
        end
      end
    end

    describe '.register_domain' do
      before { allow(client).to receive(:register_domain).and_return(nil) }

      it 'registers domain with the specified name' do
        described_class.register_domain('new-domain')

        expect(client)
          .to have_received(:register_domain)
          .with(name: 'new-domain', description: nil)
      end

      it 'registers domain with the specified name and description' do
        described_class.register_domain('new-domain', 'domain description')

        expect(client)
          .to have_received(:register_domain)
          .with(name: 'new-domain', description: 'domain description')
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
    it 'returns Cadence::Configuration object' do
      expect(described_class.configuration).to be_an_instance_of(Cadence::Configuration)
    end
  end

  describe '.logger' do
    it 'returns preconfigured Cadence logger' do
      expect(described_class.logger).to eq(described_class.configuration.logger)
    end
  end
end
