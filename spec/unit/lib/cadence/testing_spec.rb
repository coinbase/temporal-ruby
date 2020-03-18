require 'cadence/testing'
require 'cadence/workflow'

describe Cadence::Testing::CadenceOverride do
  class TestCadenceOverrideWorkflow < Cadence::Workflow
    domain 'default-domain'
    task_list 'default-task-list'

    def execute; end
  end

  context 'when testing mode is disabled' do
    describe 'Cadence.start_workflow' do
      let(:client) { instance_double('Cadence::Client::ThriftClient') }
      let(:response) { CadenceThrift::StartWorkflowExecutionResponse.new(runId: 'xxx') }

      before { allow(Cadence::Client).to receive(:generate).and_return(client) }
      after { Cadence.remove_instance_variable(:@client) }

      it 'invokes original implementation' do
        allow(client).to receive(:start_workflow_execution).and_return(response)

        Cadence.start_workflow(TestCadenceOverrideWorkflow)

        expect(client)
          .to have_received(:start_workflow_execution)
          .with(hash_including(workflow_name: 'TestCadenceOverrideWorkflow'))
      end
    end
  end

  context 'when testing mode is local' do
    around do |example|
      Cadence::Testing.local! { example.run }
    end

    describe 'Cadence.start_workflow' do
      let(:workflow) { TestCadenceOverrideWorkflow.new(nil) }

      before { allow(TestCadenceOverrideWorkflow).to receive(:new).and_return(workflow) }

      it 'calls the workflow directly' do
        allow(workflow).to receive(:execute)

        Cadence.start_workflow(TestCadenceOverrideWorkflow)

        expect(workflow).to have_received(:execute)
        expect(TestCadenceOverrideWorkflow)
          .to have_received(:new)
          .with(an_instance_of(Cadence::Testing::LocalWorkflowContext))
      end

      describe 'execution control' do
        subject do
          Cadence.start_workflow(
            TestCadenceOverrideWorkflow,
            options: { workflow_id: workflow_id, workflow_id_reuse_policy: policy }
          )
        end

        let(:workflow_id) { SecureRandom.uuid }
        let(:error_class) { CadenceThrift::WorkflowExecutionAlreadyStartedError }

        before { Cadence.send(:executions)[workflow_id] = state }

        context 'reuse policy is :allow_failed' do
          let(:policy) { :allow_failed }

          context 'when workflow was not yet started' do
            let(:state) { nil }

            it { is_expected.to eq(nil) }
          end

          context 'when workflow is started' do
            let(:state) { :started }

            it 'raises error' do
              expect { subject }.to raise_error(error_class)
            end
          end

          context 'when workflow has completed' do
            let(:state) { :completed }

            it 'raises error' do
              expect { subject }.to raise_error(error_class)
            end
          end

          context 'when workflow has failed' do
            let(:state) { :failed }

            it { is_expected.to eq(nil) }
          end
        end

        context 'reuse policy is :allow' do
          let(:policy) { :allow }

          context 'when workflow was not yet started' do
            let(:state) { nil }

            it { is_expected.to eq(nil) }
          end

          context 'when workflow is started' do
            let(:state) { :started }

            it 'raises error' do
              expect { subject }.to raise_error(error_class)
            end
          end

          context 'when workflow has completed' do
            let(:state) { :completed }

            it { is_expected.to eq(nil) }
          end

          context 'when workflow has failed' do
            let(:state) { :failed }

            it { is_expected.to eq(nil) }
          end
        end

        context 'reuse policy is :reject' do
          let(:policy) { :reject }

          context 'when workflow was not yet started' do
            let(:state) { nil }

            it { is_expected.to eq(nil) }
          end

          context 'when workflow is started' do
            let(:state) { :started }

            it 'raises error' do
              expect { subject }.to raise_error(error_class)
            end
          end

          context 'when workflow has completed' do
            let(:state) { :completed }

            it 'raises error' do
              expect { subject }.to raise_error(error_class)
            end
          end

          context 'when workflow has failed' do
            let(:state) { :failed }

            it 'raises error' do
              expect { subject }.to raise_error(error_class)
            end
          end
        end
      end
    end
  end
end
