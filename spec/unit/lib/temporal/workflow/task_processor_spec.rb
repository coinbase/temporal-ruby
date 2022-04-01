require 'temporal/workflow/task_processor'
require 'temporal/middleware/chain'
require 'temporal/configuration'

describe Temporal::Workflow::TaskProcessor do
  subject { described_class.new(task, namespace, lookup, middleware_chain, config) }

  let(:namespace) { 'test-namespace' }
  let(:lookup) { instance_double('Temporal::ExecutableLookup', find: nil) }
  let(:query) { nil }
  let(:queries) { nil }
  let(:task) { Fabricate(:api_workflow_task, { workflow_type: api_workflow_type, query: query, queries: queries }.compact) }
  let(:api_workflow_type) { Fabricate(:api_workflow_type, name: workflow_name) }
  let(:workflow_name) { 'TestWorkflow' }
  let(:connection) { instance_double('Temporal::Connection::GRPC') }
  let(:middleware_chain) { Temporal::Middleware::Chain.new }
  let(:input) { ['arg1', 'arg2'] }
  let(:config) { Temporal::Configuration.new }

  describe '#process' do
    let(:context) { instance_double('Temporal::Workflow::Context') }

    before do
      allow(Temporal::Connection)
        .to receive(:generate)
        .with(config.for_connection)
        .and_return(connection)
      allow(connection).to receive(:respond_workflow_task_completed)
      allow(connection).to receive(:respond_query_task_completed)
      allow(connection).to receive(:respond_workflow_task_failed)

      allow(middleware_chain).to receive(:invoke).and_call_original

      allow(Temporal.metrics).to receive(:timing)
    end

    context 'when workflow is not registered' do
      it 'ignores connection exception' do
        allow(connection)
          .to receive(:respond_workflow_task_failed)
          .and_raise(StandardError)

        subject.process
      end

      it 'calls error_handlers' do
        reported_error = nil
        reported_metadata = nil

        config.on_error do |error, metadata: nil|
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
        allow(Temporal::Workflow::Executor).to receive(:new).and_return(executor)
        allow(executor).to receive(:run) { workflow_class.execute_in_context(context, input); commands }
        allow(executor).to receive(:process_queries)
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

        context 'when workflow task queries are included' do
          let(:query_id) { SecureRandom.uuid }
          let(:query_result) { Temporal::Workflow::QueryResult.answer(42) }
          let(:queries) do
            Google::Protobuf::Map.new(:string, :message, Temporal::Api::Query::V1::WorkflowQuery).tap do |map|
              map[query_id] = Fabricate(:api_workflow_query)
            end
          end

          before do
            allow(executor).to receive(:process_queries).and_return(query_id => query_result)
          end

          it 'completes the workflow task with query results' do
            subject.process

            expect(executor)
              .to have_received(:process_queries)
              .with(query_id => an_instance_of(Temporal::Workflow::TaskProcessor::Query))
            expect(connection)
              .to have_received(:respond_workflow_task_completed)
              .with(
                namespace: namespace,
                task_token: task.task_token,
                commands: commands,
                query_results: { query_id => query_result }
              )
          end
        end

        context 'when deprecated task query is present' do
          let(:query) { Fabricate(:api_workflow_query) }
          let(:result) { Temporal::Workflow::QueryResult.answer(42) }

          before do
            allow(executor).to receive(:process_queries).and_return(legacy_query: result)
          end

          it 'completes the workflow query task with the result' do
            subject.process

            expect(executor).to have_received(:process_queries).with(
              legacy_query: an_instance_of(Temporal::Workflow::TaskProcessor::Query)
            )
            expect(connection).to_not have_received(:respond_workflow_task_completed)
            expect(connection)
              .to have_received(:respond_query_task_completed)
              .with(
                task_token: task.task_token,
                namespace: namespace,
                query_result: result
              )
          end
        end

        context 'when deprecated task query is not present' do
          it 'completes the workflow task' do
            subject.process

            expect(connection).to_not have_received(:respond_query_task_completed)
            expect(connection)
              .to have_received(:respond_workflow_task_completed)
              .with(namespace: namespace, task_token: task.task_token, commands: commands, query_results: nil)
          end

          it 'ignores connection exception' do
            allow(connection)
              .to receive(:respond_workflow_task_completed)
              .and_raise(StandardError)

            subject.process
          end
        end

        it 'sends queue_time metric' do
          subject.process

          expect(Temporal.metrics)
            .to have_received(:timing)
            .with('workflow_task.queue_time', an_instance_of(Integer), workflow: workflow_name, namespace: namespace)
        end

        it 'sends latency metric' do
          subject.process

          expect(Temporal.metrics)
            .to have_received(:timing)
            .with('workflow_task.latency', an_instance_of(Integer), workflow: workflow_name, namespace: namespace)
        end
      end

      context 'when workflow task raises an exception' do
        let(:exception) { StandardError.new('workflow task failed') }

        before { allow(workflow_class).to receive(:execute_in_context).and_raise(exception) }

        context 'when deprecated task query is present' do
          let(:query) { Fabricate(:api_workflow_query) }

          it 'fails the workflow task' do
            subject.process

            expect(connection)
              .to have_received(:respond_workflow_task_failed)
              .with(
                namespace: namespace,
                task_token: task.task_token,
                cause: Temporal::Api::Enums::V1::WorkflowTaskFailedCause::WORKFLOW_TASK_FAILED_CAUSE_WORKFLOW_WORKER_UNHANDLED_FAILURE,
                exception: exception
              )
          end
        end

        context 'when deprecated task query is not present' do
          it 'fails the workflow task' do
            subject.process

            expect(connection)
              .to have_received(:respond_workflow_task_failed)
              .with(
                namespace: namespace,
                task_token: task.task_token,
                cause: Temporal::Api::Enums::V1::WorkflowTaskFailedCause::WORKFLOW_TASK_FAILED_CAUSE_WORKFLOW_WORKER_UNHANDLED_FAILURE,
                exception: exception
              )
          end

          it 'does not fail the task beyond the first attempt' do
            task.attempt = 2
            subject.process

            expect(connection)
              .not_to have_received(:respond_workflow_task_failed)
          end

          it 'ignores connection exception' do
            allow(connection)
              .to receive(:respond_workflow_task_failed)
              .and_raise(StandardError)

            subject.process
          end

          it 'calls error_handlers' do
            reported_error = nil
            reported_metadata = nil

            config.on_error do |error, metadata: nil|
              reported_error = error
              reported_metadata = metadata
            end

            subject.process

            expect(reported_error).to be_an_instance_of(StandardError)
            expect(reported_metadata).to be_an_instance_of(Temporal::Metadata::WorkflowTask)
          end
        end

        it 'sends queue_time metric' do
          subject.process

          expect(Temporal.metrics)
            .to have_received(:timing)
            .with('workflow_task.queue_time', an_instance_of(Integer), workflow: workflow_name, namespace: namespace)
        end

        it 'sends latency metric' do
          subject.process

          expect(Temporal.metrics)
            .to have_received(:timing)
            .with('workflow_task.latency', an_instance_of(Integer), workflow: workflow_name, namespace: namespace)
        end
      end

      context 'when legacy query fails' do
        let(:query) { Fabricate(:api_workflow_query) }
        let(:exception) { StandardError.new('workflow task failed') }
        let(:query_failure) { Temporal::Workflow::QueryResult.failure(exception) }

        before do
          allow(executor)
            .to receive(:process_queries)
            .and_return(legacy_query: query_failure)
        end

        it 'fails the workflow task' do
          subject.process

          expect(connection)
            .to have_received(:respond_query_task_completed)
            .with(
              namespace: namespace,
              task_token: task.task_token,
              query_result: query_failure
            )
        end
      end

      context 'when history is paginated' do
        let(:task) { Fabricate(:api_paginated_workflow_task, workflow_type: api_workflow_type) }
        let(:event) { Fabricate(:api_workflow_execution_started_event) }
        let(:history_response) { Fabricate(:workflow_execution_history, events: [event]) }

        before do
          allow(connection)
            .to receive(:get_workflow_execution_history)
            .and_return(history_response)
        end

        it 'fetches additional pages' do
          subject.process

          expect(connection)
            .to have_received(:get_workflow_execution_history)
            .with(
              namespace: namespace,
              workflow_id: task.workflow_execution.workflow_id,
              run_id: task.workflow_execution.run_id,
              next_page_token: task.next_page_token
            )
            .once
        end

        context 'when a page has no events' do
          let(:history_response) { Fabricate(:workflow_execution_history, events: []) }

          it 'fails a workflow task' do
            subject.process

            expect(connection)
              .to have_received(:respond_workflow_task_failed)
              .with(
                namespace: namespace,
                task_token: task.task_token,
                cause: Temporal::Api::Enums::V1::WorkflowTaskFailedCause::WORKFLOW_TASK_FAILED_CAUSE_WORKFLOW_WORKER_UNHANDLED_FAILURE,
                exception: an_instance_of(Temporal::UnexpectedResponse)
              )
          end
        end
      end
    end
  end
end
