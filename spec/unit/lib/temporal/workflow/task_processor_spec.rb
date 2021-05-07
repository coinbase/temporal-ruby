require 'temporal/workflow/task_processor'
require 'temporal/middleware/chain'

describe Temporal::Workflow::TaskProcessor do
  subject { described_class.new(task, namespace, lookup, client, middleware_chain) }

  let(:namespace) { 'test-namespace' }
  let(:lookup) { instance_double('Temporal::ExecutableLookup', find: nil) }
  let(:task) do
    Fabricate(
      :api_workflow_task,
      workflow_type: Fabricate(:api_workflow_type, name: workflow_name)
    )
  end
  let(:workflow_name) { 'TestWorkflow' }
  let(:client) { instance_double('Temporal::Client::GRPCClient') }
  let(:middleware_chain) { Temporal::Middleware::Chain.new }
  let(:input) { ['arg1', 'arg2'] }

  describe '#process' do
    let(:context) { instance_double('Temporal::Workflow::Context') }

    before do
      allow(client).to receive(:respond_workflow_task_completed)
      allow(client).to receive(:respond_workflow_task_failed)

      allow(middleware_chain).to receive(:invoke).and_call_original

      allow(Temporal.metrics).to receive(:timing)
    end

    context 'when workflow is not registered' do
      it 'ignores client exception' do
        allow(client)
          .to receive(:respond_workflow_task_failed)
          .and_raise(StandardError)

        subject.process
      end

      it 'calls error_handlers' do
        reported_error = nil
        reported_metadata = nil

        Temporal.configuration.on_error do |error, metadata: nil|
          reported_error = error
          reported_metadata = metadata
        end

        subject.process

        expect(reported_error).to be_an_instance_of(Temporal::WorkflowNotRegistered)
        expect(reported_metadata).to be_an_instance_of(Temporal::Metadata::WorkflowTask)
      end
    end

    context 'when workflow is registered' do
      let(:workflow_class) { double('Temporal::Workflow', execute_in_context: nil) }
      let(:executor) { double('Temporal::Workflow::Executor') }
      let(:commands) { double('commands') }

      before do
        allow(lookup).to receive(:find).with(workflow_name).and_return(workflow_class)
        allow(subject).to receive(:fetch_full_history)
        allow(Temporal::Workflow::Executor).to receive(:new).and_return(executor)
        allow(executor).to receive(:run) { workflow_class.execute_in_context(context, input); commands }
      end

      context 'when workflow task completes' do
        # Note: This is a bit of a pointless test because I short circuit this with stubs.
        # The code does not drop down into the state machine and so forth.
        it 'runs the specified task' do
          subject.process

          expect(workflow_class).to have_received(:execute_in_context).with(context, input)
        end

        it 'invokes the middleware chain' do
          subject.process

          expect(middleware_chain).to have_received(:invoke).with(
            an_instance_of(Temporal::Metadata::WorkflowTask)
          )
        end

        it 'completes the workflow task' do
          subject.process

          expect(client)
            .to have_received(:respond_workflow_task_completed)
            .with(task_token: task.task_token, commands: commands)
        end

        it 'ignores client exception' do
          allow(client)
            .to receive(:respond_workflow_task_completed)
            .and_raise(StandardError)

          subject.process
        end

        it 'sends queue_time metric' do
          subject.process

          expect(Temporal.metrics)
            .to have_received(:timing)
            .with('workflow_task.queue_time', an_instance_of(Integer), workflow: workflow_name)
        end

        it 'sends latency metric' do
          subject.process

          expect(Temporal.metrics)
            .to have_received(:timing)
            .with('workflow_task.latency', an_instance_of(Integer), workflow: workflow_name)
        end
      end

      context 'when workflow task raises an exception' do
        let(:exception) { StandardError.new('workflow task failed') }

        before { allow(workflow_class).to receive(:execute_in_context).and_raise(exception) }

        it 'fails the workflow task' do
          subject.process

          expect(client)
            .to have_received(:respond_workflow_task_failed)
            .with(
              task_token: task.task_token,
              cause: Temporal::Api::Enums::V1::WorkflowTaskFailedCause::WORKFLOW_TASK_FAILED_CAUSE_UNHANDLED_COMMAND,
              exception: exception
            )
        end

        it 'does not fail the task beyond the first attempt' do
          task.attempt = 2
          subject.process

          expect(client)
            .not_to have_received(:respond_workflow_task_failed)
        end

        it 'ignores client exception' do
          allow(client)
            .to receive(:respond_workflow_task_failed)
            .and_raise(StandardError)

          subject.process
        end

        it 'calls error_handlers' do
          reported_error = nil
          reported_metadata = nil

          Temporal.configuration.on_error do |error, metadata: nil|
            reported_error = error
            reported_metadata = metadata
          end

          subject.process

          expect(reported_error).to be_an_instance_of(StandardError)
          expect(reported_metadata).to be_an_instance_of(Temporal::Metadata::WorkflowTask)
        end

        it 'sends queue_time metric' do
          subject.process

          expect(Temporal.metrics)
            .to have_received(:timing)
            .with('workflow_task.queue_time', an_instance_of(Integer), workflow: workflow_name)
        end

        it 'sends latency metric' do
          subject.process

          expect(Temporal.metrics)
            .to have_received(:timing)
            .with('workflow_task.latency', an_instance_of(Integer), workflow: workflow_name)
        end
      end
    end
  end
end
