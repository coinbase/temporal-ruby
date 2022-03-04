require 'temporal/testing'
require 'temporal/workflow'
require 'temporal/api/errordetails/v1/message_pb'

describe Temporal::Testing::TemporalOverride do
  let(:client) { Temporal::Client.new(config) }
  let(:config) { Temporal::Configuration.new }

  class TestTemporalOverrideWorkflow < Temporal::Workflow
    namespace 'default-namespace'
    task_queue 'default-task-queue'

    def execute; end
  end

  class UpsertSearchAttributesWorkflow < Temporal::Workflow
    namespace 'default-namespace'
    task_queue 'default-task-queue'

    def execute
      workflow.upsert_search_attributes('CustomIntField' => 5)
    end
  end

  context 'when testing mode is disabled' do
    describe 'Temporal.start_workflow' do
      let(:connection) { instance_double('Temporal::Connection::GRPC') }
      let(:response) { Temporal::Api::WorkflowService::V1::StartWorkflowExecutionResponse.new(run_id: 'xxx') }

      before { allow(Temporal::Connection).to receive(:generate).and_return(connection) }
      after { client.remove_instance_variable(:@connection) rescue NameError }

      it 'invokes original implementation' do
        allow(connection).to receive(:start_workflow_execution).and_return(response)

        client.start_workflow(TestTemporalOverrideWorkflow)

        expect(connection)
          .to have_received(:start_workflow_execution)
          .with(hash_including(workflow_name: 'TestTemporalOverrideWorkflow'))
      end
    end
  end

  context 'when testing mode is local' do
    around do |example|
      Temporal::Testing.local! { example.run }
    end

    describe 'Temporal.schedule_workflow' do
      it 'allows the test to simulate deferred executions' do
        workflow = TestTemporalOverrideWorkflow.new(nil)
        workflow2 = TestTemporalOverrideWorkflow.new(nil)
        allow(TestTemporalOverrideWorkflow).to receive(:new).and_return(workflow, workflow2)

        allow(workflow).to receive(:execute)
        allow(workflow2).to receive(:execute)
        client.schedule_workflow(TestTemporalOverrideWorkflow, '* * * * *')
        client.schedule_workflow(TestTemporalOverrideWorkflow, '1 */5 * * *')
        expect(workflow).not_to have_received(:execute)
        expect(workflow2).not_to have_received(:execute)

        Temporal::Testing::ScheduledWorkflows.execute_all
        expect(workflow).to have_received(:execute)
        expect(workflow2).to have_received(:execute)
      end

      it 'allows the test to simulate a particular deferred execution' do
        workflow = TestTemporalOverrideWorkflow.new(nil)
        allow(TestTemporalOverrideWorkflow).to receive(:new).and_return(workflow)
        allow(workflow).to receive(:execute)
        client.schedule_workflow(TestTemporalOverrideWorkflow, '*/3 * * * *', options: { workflow_id: 'my_id' })
        expect(workflow).not_to have_received(:execute)
        expect(Temporal::Testing::ScheduledWorkflows.cron_schedules['my_id']).to eq('*/3 * * * *')

        Temporal::Testing::ScheduledWorkflows.execute(workflow_id: 'my_id')
        expect(workflow).to have_received(:execute)
      end

      it 'complains when an invalid deferred execution is specified' do
        expect do
          Temporal::Testing::ScheduledWorkflows.execute(workflow_id: 'invalid_id')
        end.to raise_error(
          Temporal::Testing::WorkflowIDNotScheduled,
          /There is no workflow with id invalid_id that was scheduled with Temporal.schedule_workflow./
        )
      end

      it 'can clear scheduled executions' do
        workflow = TestTemporalOverrideWorkflow.new(nil)
        allow(TestTemporalOverrideWorkflow).to receive(:new).and_return(workflow)
        allow(workflow).to receive(:execute)
        client.schedule_workflow(TestTemporalOverrideWorkflow, '* * * * *')
        expect(workflow).not_to have_received(:execute)
        expect(Temporal::Testing::ScheduledWorkflows.cron_schedules).not_to be_empty

        Temporal::Testing::ScheduledWorkflows.clear_all
        Temporal::Testing::ScheduledWorkflows.execute_all
        expect(workflow).not_to have_received(:execute)
        expect(Temporal::Testing::ScheduledWorkflows.cron_schedules).to be_empty
      end
    end

    describe 'Workflow.execute_locally' do
      it 'executes the workflow' do
        workflow = TestTemporalOverrideWorkflow.new(nil)
        allow(TestTemporalOverrideWorkflow).to receive(:new).and_return(workflow)
        allow(workflow).to receive(:execute)

        TestTemporalOverrideWorkflow.execute_locally

        expect(workflow).to have_received(:execute)
      end

      it 'restores original context after finishing successfully' do
        TestTemporalOverrideWorkflow.execute_locally
        expect(Temporal::ThreadLocalContext.get).to eq(nil)
      end

      class FailingWorkflow
        def execute
          raise 'uh oh'
        end
      end

      it 'restores original context after failing' do
        expect { FailingWorkflow.execute_locally }.to raise_error(StandardError)
        expect(Temporal::ThreadLocalContext.get).to eq(nil)
      end
    end

    describe 'Temporal.start_workflow' do
      let(:workflow) { TestTemporalOverrideWorkflow.new(nil) }

      before { allow(TestTemporalOverrideWorkflow).to receive(:new).and_return(workflow) }

      it 'calls the workflow directly' do
        allow(workflow).to receive(:execute)

        client.start_workflow(TestTemporalOverrideWorkflow)

        expect(workflow).to have_received(:execute)
        expect(TestTemporalOverrideWorkflow)
          .to have_received(:new)
          .with(an_instance_of(Temporal::Testing::LocalWorkflowContext))
      end

      it 'explicitly does not support staring a workflow with a signal' do
        expect {
          client.start_workflow(TestTemporalOverrideWorkflow, options: { signal_name: 'breakme' })
        }.to raise_error(NotImplementedError) do |e|
          expect(e.message).to eql("Signals are not available when Temporal::Testing.local! is on")
        end
      end

      describe 'execution control' do
        subject do
          client.start_workflow(
            TestTemporalOverrideWorkflow,
            options: { workflow_id: workflow_id, workflow_id_reuse_policy: policy }
          )
        end

        let(:execution) { instance_double(Temporal::Testing::WorkflowExecution, status: status) }
        let(:workflow_id) { SecureRandom.uuid }
        let(:run_id) { SecureRandom.uuid }
        let(:error_class) { Temporal::WorkflowExecutionAlreadyStartedFailure }

        # Simulate existing execution
        before do
          if execution
            client.send(:executions)[[workflow_id, run_id]] = execution
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
              expect { subject }.to raise_error(error_class) { |e| expect(e.run_id).to eql(run_id) }
            end
          end

          context 'when workflow has completed' do
            let(:status) { Temporal::Workflow::ExecutionInfo::COMPLETED_STATUS }

            it 'raises error' do
              expect { subject }.to raise_error(error_class) { |e| expect(e.run_id).to eql(run_id) }
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
              expect { subject }.to raise_error(error_class) { |e| expect(e.run_id).to eql(run_id) }
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
              expect { subject }.to raise_error(error_class) { |e| expect(e.run_id).to eql(run_id) }
            end
          end

          context 'when workflow has completed' do
            let(:status) { Temporal::Workflow::ExecutionInfo::COMPLETED_STATUS }

            it 'raises error' do
              expect { subject }.to raise_error(error_class) { |e| expect(e.run_id).to eql(run_id) }
            end
          end

          context 'when workflow has failed' do
            let(:status) { Temporal::Workflow::ExecutionInfo::FAILED_STATUS }

            it 'raises error' do
              expect { subject }.to raise_error(error_class) { |e| expect(e.run_id).to eql(run_id) }
            end
          end
        end
      end

      describe 'Temporal.fetch_workflow_execution_info' do
        it 'retrieves search attributes' do
          workflow_id = 'upsert_search_attributes_test_wf-' + SecureRandom.uuid

          run_id = client.start_workflow(
            UpsertSearchAttributesWorkflow,
            options: {
              workflow_id: workflow_id,
            },
          )

          info = client.fetch_workflow_execution_info('default-namespace', workflow_id, run_id)
          expect(info.search_attributes).to eq({'CustomIntField' => 5})
        end

      end
    end
  end
end
