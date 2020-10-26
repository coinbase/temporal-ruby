require 'temporal/testing'
require 'temporal/workflow'

describe Temporal::Testing::TemporalOverride do
  class TestTemporalOverrideWorkflow < Temporal::Workflow
    namespace 'default-namespace'
    task_list 'default-task-list'

    def execute; end
  end

  context 'when testing mode is disabled' do
    describe 'Temporal.start_workflow' do
      let(:client) { instance_double('Temporal::Client::ThriftClient') }
      let(:response) { TemporalThrift::StartWorkflowExecutionResponse.new(runId: 'xxx') }

      before { allow(Temporal::Client).to receive(:generate).and_return(client) }
      after { Temporal.remove_instance_variable(:@client) }

      it 'invokes original implementation' do
        allow(client).to receive(:start_workflow_execution).and_return(response)

        Temporal.start_workflow(TestTemporalOverrideWorkflow)

        expect(client)
          .to have_received(:start_workflow_execution)
          .with(hash_including(workflow_name: 'TestTemporalOverrideWorkflow'))
      end
    end
  end

  context 'when testing mode is local' do
    around do |example|
      Temporal::Testing.local! { example.run }
    end

    describe 'Temporal.start_workflow' do
      let(:workflow) { TestTemporalOverrideWorkflow.new(nil) }

      before { allow(TestTemporalOverrideWorkflow).to receive(:new).and_return(workflow) }

      it 'calls the workflow directly' do
        allow(workflow).to receive(:execute)

        Temporal.start_workflow(TestTemporalOverrideWorkflow)

        expect(workflow).to have_received(:execute)
        expect(TestTemporalOverrideWorkflow)
          .to have_received(:new)
          .with(an_instance_of(Temporal::Testing::LocalWorkflowContext))
      end

      describe 'execution control' do
        subject do
          Temporal.start_workflow(
            TestTemporalOverrideWorkflow,
            options: { workflow_id: workflow_id, workflow_id_reuse_policy: policy }
          )
        end

        let(:execution) { instance_double(Temporal::Testing::WorkflowExecution, status: status) }
        let(:workflow_id) { SecureRandom.uuid }
        let(:run_id) { SecureRandom.uuid }
        let(:error_class) { TemporalThrift::WorkflowExecutionAlreadyStartedError }

        # Simulate exiwting execution
        before do
          if execution
            Temporal.send(:executions)[[workflow_id, run_id]] = execution
          end
        end

        context 'reuse policy is :allow_failed' do
          let(:policy) { :allow_failed }

          context 'when workflow was not yet started' do
            let(:execution) { nil }

            it { is_expected.to be_a(String) }
          end

          context 'when workflow is started' do
            let(:status) { Temporal::Workflow::ExecutionInfo::RUNNING_STATUS }

            it 'raises error' do
              expect { subject }.to raise_error(error_class)
            end
          end

          context 'when workflow has completed' do
            let(:status) { Temporal::Workflow::ExecutionInfo::COMPLETED_STATUS }

            it 'raises error' do
              expect { subject }.to raise_error(error_class)
            end
          end

          context 'when workflow has failed' do
            let(:status) { Temporal::Workflow::ExecutionInfo::FAILED_STATUS }

            it { is_expected.to be_a(String) }
          end
        end

        context 'reuse policy is :allow' do
          let(:policy) { :allow }

          context 'when workflow was not yet started' do
            let(:execution) { nil }

            it { is_expected.to be_a(String) }
          end

          context 'when workflow is started' do
            let(:status) { Temporal::Workflow::ExecutionInfo::RUNNING_STATUS }

            it 'raises error' do
              expect { subject }.to raise_error(error_class)
            end
          end

          context 'when workflow has completed' do
            let(:status) { Temporal::Workflow::ExecutionInfo::COMPLETED_STATUS }

            it { is_expected.to be_a(String) }
          end

          context 'when workflow has failed' do
            let(:status) { Temporal::Workflow::ExecutionInfo::FAILED_STATUS }

            it { is_expected.to be_a(String) }
          end
        end

        context 'reuse policy is :reject' do
          let(:policy) { :reject }

          context 'when workflow was not yet started' do
            let(:execution) { nil }

            it { is_expected.to be_a(String) }
          end

          context 'when workflow is started' do
            let(:status) { Temporal::Workflow::ExecutionInfo::RUNNING_STATUS }

            it 'raises error' do
              expect { subject }.to raise_error(error_class)
            end
          end

          context 'when workflow has completed' do
            let(:status) { Temporal::Workflow::ExecutionInfo::COMPLETED_STATUS }

            it 'raises error' do
              expect { subject }.to raise_error(error_class)
            end
          end

          context 'when workflow has failed' do
            let(:status) { Temporal::Workflow::ExecutionInfo::FAILED_STATUS }

            it 'raises error' do
              expect { subject }.to raise_error(error_class)
            end
          end
        end
      end
    end
  end
end
