require 'temporal/connection/grpc'
require 'temporal/workflow/query_result'

describe Temporal::Connection::GRPC do
  let(:identity) { 'my-identity' }
  let(:binary_checksum) { 'v1.0.0' }
  let(:grpc_stub) { double('grpc stub') }
  let(:grpc_operator_stub) { double('grpc stub') }
  let(:namespace) { 'test-namespace' }
  let(:workflow_id) { SecureRandom.uuid }
  let(:run_id) { SecureRandom.uuid }
  let(:now) { Time.now}

  subject { Temporal::Connection::GRPC.new(nil, nil, identity, :this_channel_is_insecure) }

  class TestDeserializer
    extend Temporal::Concerns::Payloads
  end

  before do
    allow(subject).to receive(:client).and_return(grpc_stub)
    allow(subject).to receive(:operator_client).and_return(grpc_operator_stub)

    allow(Time).to receive(:now).and_return(now)
  end

  describe '#start_workflow_execution' do
    it 'provides the existing run_id when the workflow is already started' do
      allow(grpc_stub).to receive(:start_workflow_execution).and_raise(
        GRPC::AlreadyExists,
        'Workflow execution already finished successfully. WorkflowId: TestWorkflow-1, RunId: baaf1d86-4459-4ecd-a288-47aeae55245d. Workflow Id reuse policy: allow duplicate workflow Id if last run failed.'
      )

      expect do
        subject.start_workflow_execution(
          namespace: namespace,
          workflow_id: workflow_id,
          workflow_name: 'Test',
          task_queue: 'test',
          execution_timeout: 0,
          run_timeout: 0,
          task_timeout: 0,
          memo: {},
          search_attributes: {},
          workflow_id_reuse_policy: :allow,
        )
      end.to raise_error(Temporal::WorkflowExecutionAlreadyStartedFailure) do |e|
        expect(e.run_id).to eql('baaf1d86-4459-4ecd-a288-47aeae55245d')
      end
    end

    it 'starts a workflow with scalar arguments' do
      allow(grpc_stub).to receive(:start_workflow_execution).and_return(Temporalio::Api::WorkflowService::V1::SignalWithStartWorkflowExecutionResponse.new(run_id: 'xxx'))

      datetime_attribute_value = Time.now
      subject.start_workflow_execution(
        namespace: namespace,
        workflow_id: workflow_id,
        workflow_name: 'workflow_name',
        task_queue: 'task_queue',
        input: ['foo'],
        execution_timeout: 1,
        run_timeout: 2,
        task_timeout: 3,
        memo: {},
        search_attributes: {
          'foo-int-attribute' => 256,
          'foo-string-attribute' => "bar",
          'foo-double-attribute' => 6.28,
          'foo-bool-attribute' => false,
          # Temporal::Workflow::Context::Helpers.process_search_attributes will have converted
          # any `Time` instances to strings by the time `start_workflow_execution` is called,
          # so do the same here.
          'foo-datetime-attribute' => datetime_attribute_value.utc.iso8601,
        },
        workflow_id_reuse_policy: :reject,
      )

      expect(grpc_stub).to have_received(:start_workflow_execution) do |request|
        expect(request).to be_an_instance_of(Temporalio::Api::WorkflowService::V1::StartWorkflowExecutionRequest)
        expect(request.namespace).to eq(namespace)
        expect(request.workflow_id).to eq(workflow_id)
        expect(request.workflow_type.name).to eq('workflow_name')
        expect(request.task_queue.name).to eq('task_queue')
        expect(request.input.payloads[0].data).to eq('"foo"')
        expect(request.workflow_execution_timeout.seconds).to eq(1)
        expect(request.workflow_run_timeout.seconds).to eq(2)
        expect(request.workflow_task_timeout.seconds).to eq(3)
        expect(request.workflow_id_reuse_policy).to eq(:WORKFLOW_ID_REUSE_POLICY_REJECT_DUPLICATE)
        expect(request.search_attributes.indexed_fields).to eq({
          'foo-int-attribute' => Temporalio::Api::Common::V1::Payload.new(data: '256', metadata: { 'encoding' => 'json/plain' }),
          'foo-string-attribute' => Temporalio::Api::Common::V1::Payload.new(data: '"bar"', metadata: { 'encoding' => 'json/plain' }),
          'foo-double-attribute' => Temporalio::Api::Common::V1::Payload.new(data: '6.28', metadata: { 'encoding' => 'json/plain' }),
          'foo-bool-attribute' => Temporalio::Api::Common::V1::Payload.new(data: 'false', metadata: { 'encoding' => 'json/plain' }),
          'foo-datetime-attribute' => Temporalio::Api::Common::V1::Payload.new(data: "\"#{datetime_attribute_value.utc.iso8601}\"", metadata: { 'encoding' => 'json/plain' }),
        })
      end
    end

    it 'raises when an invalid workflow_id_reuse_policy is given' do
      expect do
        subject.start_workflow_execution(
          namespace: namespace,
          workflow_id: workflow_id,
          workflow_name: 'Test',
          task_queue: 'test',
          execution_timeout: 0,
          run_timeout: 0,
          task_timeout: 0,
          memo: {},
          search_attributes: {},
          workflow_id_reuse_policy: :not_a_valid_policy
        )
      end.to raise_error(Temporal::Connection::ArgumentError) do |e|
        expect(e.message).to eq('Unknown workflow_id_reuse_policy specified: not_a_valid_policy')
      end
    end
  end

  describe '#signal_with_start_workflow' do
    let(:temporal_response) do
      Temporalio::Api::WorkflowService::V1::SignalWithStartWorkflowExecutionResponse.new(run_id: 'xxx')
    end

    before { allow(grpc_stub).to receive(:signal_with_start_workflow_execution).and_return(temporal_response) }

    it 'starts a workflow with a signal with scalar arguments' do
      subject.signal_with_start_workflow_execution(
        namespace: namespace,
        workflow_id: workflow_id,
        workflow_name: 'workflow_name',
        task_queue: 'task_queue',
        input: ['foo'],
        execution_timeout: 1,
        run_timeout: 2,
        task_timeout: 3,
        workflow_id_reuse_policy: :allow,
        signal_name: 'the question',
        signal_input: 'what do you get if you multiply six by nine?'
      )

      expect(grpc_stub).to have_received(:signal_with_start_workflow_execution) do |request|
        expect(request).to be_an_instance_of(Temporalio::Api::WorkflowService::V1::SignalWithStartWorkflowExecutionRequest)
        expect(request.namespace).to eq(namespace)
        expect(request.workflow_id).to eq(workflow_id)
        expect(request.workflow_type.name).to eq('workflow_name')
        expect(request.task_queue.name).to eq('task_queue')
        expect(request.input.payloads[0].data).to eq('"foo"')
        expect(request.workflow_execution_timeout.seconds).to eq(1)
        expect(request.workflow_run_timeout.seconds).to eq(2)
        expect(request.workflow_task_timeout.seconds).to eq(3)
        expect(request.signal_name).to eq('the question')
        expect(request.signal_input.payloads[0].data).to eq('"what do you get if you multiply six by nine?"')
        expect(request.workflow_id_reuse_policy).to eq(:WORKFLOW_ID_REUSE_POLICY_ALLOW_DUPLICATE)
      end
    end

    it 'raises when an invalid workflow_id_reuse_policy is given' do
      expect do
        subject.signal_with_start_workflow_execution(
          namespace: namespace,
          workflow_id: workflow_id,
          workflow_name: 'Test',
          task_queue: 'test',
          execution_timeout: 0,
          run_timeout: 0,
          task_timeout: 0,
          memo: {},
          search_attributes: {},
          workflow_id_reuse_policy: :not_a_valid_policy,
          signal_name: 'the question',
          signal_input: 'what do you get if you multiply six by nine?'
        )
      end.to raise_error(Temporal::Connection::ArgumentError) do |e|
        expect(e.message).to eq('Unknown workflow_id_reuse_policy specified: not_a_valid_policy')
      end
    end
  end

  describe "#list_namespaces" do
    let (:response) do
      Temporalio::Api::WorkflowService::V1::ListNamespacesResponse.new(
        namespaces: [Temporalio::Api::WorkflowService::V1::DescribeNamespaceResponse.new],
        next_page_token: ""
      )
    end

    before { allow(grpc_stub).to receive(:list_namespaces).and_return(response) }

    it 'calls GRPC service with supplied arguments' do
      next_page_token = "next-page-token-id"

      subject.list_namespaces(
        page_size: 10,
        next_page_token: next_page_token,
      )

      expect(grpc_stub).to have_received(:list_namespaces) do |request|
        expect(request).to be_an_instance_of(Temporalio::Api::WorkflowService::V1::ListNamespacesRequest)
        expect(request.page_size).to eq(10)
        expect(request.next_page_token).to eq(next_page_token)
      end
    end
  end

  describe '#get_workflow_execution_history' do
    let(:response) do
      Temporalio::Api::WorkflowService::V1::GetWorkflowExecutionHistoryResponse.new(
        history: Temporalio::Api::History::V1::History.new,
        next_page_token: nil
      )
    end

    before { allow(grpc_stub).to receive(:get_workflow_execution_history).and_return(response) }

    it 'calls GRPC service with supplied arguments' do
      subject.get_workflow_execution_history(
        namespace: namespace,
        workflow_id: workflow_id,
        run_id: run_id
      )

      expect(grpc_stub).to have_received(:get_workflow_execution_history) do |request|
        expect(request).to be_an_instance_of(Temporalio::Api::WorkflowService::V1::GetWorkflowExecutionHistoryRequest)
        expect(request.namespace).to eq(namespace)
        expect(request.execution.workflow_id).to eq(workflow_id)
        expect(request.execution.run_id).to eq(run_id)
        expect(request.next_page_token).to be_empty
        expect(request.wait_new_event).to eq(false)
        expect(request.history_event_filter_type).to eq(
          Temporalio::Api::Enums::V1::HistoryEventFilterType.lookup(
            Temporalio::Api::Enums::V1::HistoryEventFilterType::HISTORY_EVENT_FILTER_TYPE_ALL_EVENT
          )
        )
      end
    end

    context 'when wait_for_new_event is true' do
      let (:timeout) { 13 }
      it 'calls GRPC service with a deadline' do
        subject.get_workflow_execution_history(
          namespace: namespace,
          workflow_id: workflow_id,
          run_id: run_id,
          wait_for_new_event: true,
          timeout: timeout
        )

        expect(grpc_stub).to have_received(:get_workflow_execution_history).with(anything, deadline: now + timeout)
      end

      it 'demands a timeout to be specified' do
        expect do
          subject.get_workflow_execution_history(
            namespace: namespace,
            workflow_id: workflow_id,
            run_id: run_id,
            wait_for_new_event: true
          )
        end.to raise_error do |e|
          expect(e.message).to eq("You must specify a timeout when wait_for_new_event = true.")
        end
      end

      it 'disallows a timeout larger than the server timeout' do
        expect do
          subject.get_workflow_execution_history(
            namespace: namespace,
            workflow_id: workflow_id,
            run_id: run_id,
            wait_for_new_event: true,
            timeout: 60
          )
        end.to raise_error(Temporal::ClientError) do |e|
          expect(e.message).to eq("You may not specify a timeout of more than 30 seconds, got: 60.")
        end
      end
    end

    context 'when event_type is :close' do
      it 'calls GRPC service' do
        subject.get_workflow_execution_history(
          namespace: namespace,
          workflow_id: workflow_id,
          run_id: run_id,
          event_type: :close
        )

        expect(grpc_stub).to have_received(:get_workflow_execution_history) do |request|
          expect(request.history_event_filter_type).to eq(
            Temporalio::Api::Enums::V1::HistoryEventFilterType.lookup(
              Temporalio::Api::Enums::V1::HistoryEventFilterType::HISTORY_EVENT_FILTER_TYPE_CLOSE_EVENT
            )
          )
        end
      end
    end

    describe '#list_open_workflow_executions' do
      let(:namespace) { 'test-namespace' }
      let(:from) { Time.now - 600 }
      let(:to) { Time.now }
      let(:args) { { namespace: namespace, from: from, to: to } }
      let(:temporal_response) do
        Temporalio::Api::WorkflowService::V1::ListOpenWorkflowExecutionsResponse.new(executions: [], next_page_token: '')
      end

      before do
        allow(grpc_stub).to receive(:list_open_workflow_executions).and_return(temporal_response)
      end

      it 'makes an API request' do
        subject.list_open_workflow_executions(**args)

        expect(grpc_stub).to have_received(:list_open_workflow_executions) do |request|
          expect(request).to be_an_instance_of(Temporalio::Api::WorkflowService::V1::ListOpenWorkflowExecutionsRequest)
          expect(request.maximum_page_size).to eq(described_class::DEFAULT_OPTIONS[:max_page_size])
          expect(request.next_page_token).to eq('')
          expect(request.start_time_filter).to be_an_instance_of(Temporalio::Api::Filter::V1::StartTimeFilter)
          expect(request.start_time_filter.earliest_time.to_time)
            .to eq(from)
          expect(request.start_time_filter.latest_time.to_time)
            .to eq(to)
          expect(request.execution_filter).to eq(nil)
          expect(request.type_filter).to eq(nil)
        end
      end

      context 'when next_page_token is supplied' do
        it 'makes an API request' do
          subject.list_open_workflow_executions(**args.merge(next_page_token: 'x'))

          expect(grpc_stub).to have_received(:list_open_workflow_executions) do |request|
            expect(request).to be_an_instance_of(Temporalio::Api::WorkflowService::V1::ListOpenWorkflowExecutionsRequest)
            expect(request.next_page_token).to eq('x')
          end
        end
      end

      context 'when workflow_id is supplied' do
        it 'makes an API request' do
          subject.list_open_workflow_executions(**args.merge(workflow_id: 'xxx'))

          expect(grpc_stub).to have_received(:list_open_workflow_executions) do |request|
            expect(request).to be_an_instance_of(Temporalio::Api::WorkflowService::V1::ListOpenWorkflowExecutionsRequest)
            expect(request.execution_filter)
              .to be_an_instance_of(Temporalio::Api::Filter::V1::WorkflowExecutionFilter)
            expect(request.execution_filter.workflow_id).to eq('xxx')
          end
        end
      end

      context 'when workflow is supplied' do
        it 'makes an API request' do
          subject.list_open_workflow_executions(**args.merge(workflow: 'TestWorkflow'))

          expect(grpc_stub).to have_received(:list_open_workflow_executions) do |request|
            expect(request).to be_an_instance_of(Temporalio::Api::WorkflowService::V1::ListOpenWorkflowExecutionsRequest)
            expect(request.type_filter).to be_an_instance_of(Temporalio::Api::Filter::V1::WorkflowTypeFilter)
            expect(request.type_filter.name).to eq('TestWorkflow')
          end
        end
      end
    end

    describe "#count_workflow_executions" do
      let(:namespace) { 'test-namespace' }
      let(:query)  { 'StartDate < 2022-04-07T20:48:20Z order by StartTime desc' }
      let(:args) { { namespace: namespace, query: query } }
      let(:temporal_response) do
        Temporalio::Api::WorkflowService::V1::CountWorkflowExecutionsResponse.new(count: 0)
      end

      before do
        allow(grpc_stub).to receive(:count_workflow_executions).and_return(temporal_response)
      end

      it 'makes an API request' do
        subject.count_workflow_executions(**args)

        expect(grpc_stub).to have_received(:count_workflow_executions) do |request|
          expect(request).to be_an_instance_of(Temporalio::Api::WorkflowService::V1::CountWorkflowExecutionsRequest)
          expect(request.namespace).to eq(namespace)
          expect(request.query).to eq(query)
        end
      end
    end
    
    describe '#list_workflow_executions' do
      let(:namespace) { 'test-namespace' }
      let(:query) { 'StartDate < 2022-04-07T20:48:20Z order by StartTime desc' }
      let(:args) { { namespace: namespace, query: query } }
      let(:temporal_response) do
        Temporalio::Api::WorkflowService::V1::ListWorkflowExecutionsResponse.new(executions: [], next_page_token: '')
      end
      let(:temporal_paginated_response) do
        Temporalio::Api::WorkflowService::V1::ListWorkflowExecutionsResponse.new(executions: [], next_page_token: 'more-results')
      end

      before do
        allow(grpc_stub).to receive(:list_workflow_executions).and_return(temporal_response)
      end

      it 'makes an API request' do
        subject.list_workflow_executions(**args)

        expect(grpc_stub).to have_received(:list_workflow_executions) do |request|
          expect(request).to be_an_instance_of(Temporalio::Api::WorkflowService::V1::ListWorkflowExecutionsRequest)
          expect(request.page_size).to eq(described_class::DEFAULT_OPTIONS[:max_page_size])
          expect(request.next_page_token).to eq('')
          expect(request.namespace).to eq(namespace)
          expect(request.query).to eq(query)
        end
      end

      context 'when next_page_token is supplied' do
        it 'makes an API request' do
          subject.list_workflow_executions(**args.merge(next_page_token: 'x'))

          expect(grpc_stub).to have_received(:list_workflow_executions) do |request|
            expect(request).to be_an_instance_of(Temporalio::Api::WorkflowService::V1::ListWorkflowExecutionsRequest)
            expect(request.next_page_token).to eq('x')
          end
        end
      end
    end

    describe '#list_closed_workflow_executions' do
      let(:namespace) { 'test-namespace' }
      let(:from) { Time.now - 600 }
      let(:to) { Time.now }
      let(:args) { { namespace: namespace, from: from, to: to } }
      let(:temporal_response) do
        Temporalio::Api::WorkflowService::V1::ListClosedWorkflowExecutionsResponse.new(executions: [], next_page_token: '')
      end

      before do
        allow(grpc_stub).to receive(:list_closed_workflow_executions).and_return(temporal_response)
      end

      it 'makes an API request' do
        subject.list_closed_workflow_executions(**args)

        expect(grpc_stub).to have_received(:list_closed_workflow_executions) do |request|
          expect(request).to be_an_instance_of(Temporalio::Api::WorkflowService::V1::ListClosedWorkflowExecutionsRequest)
          expect(request.maximum_page_size).to eq(described_class::DEFAULT_OPTIONS[:max_page_size])
          expect(request.next_page_token).to eq('')
          expect(request.start_time_filter).to be_an_instance_of(Temporalio::Api::Filter::V1::StartTimeFilter)
          expect(request.start_time_filter.earliest_time.to_time)
            .to eq(from)
          expect(request.start_time_filter.latest_time.to_time)
            .to eq(to)
          expect(request.execution_filter).to eq(nil)
          expect(request.type_filter).to eq(nil)
          expect(request.status_filter).to eq(nil)
        end
      end

      context 'when next_page_token is supplied' do
        it 'makes an API request' do
          subject.list_closed_workflow_executions(**args.merge(next_page_token: 'x'))

          expect(grpc_stub).to have_received(:list_closed_workflow_executions) do |request|
            expect(request).to be_an_instance_of(Temporalio::Api::WorkflowService::V1::ListClosedWorkflowExecutionsRequest)
            expect(request.next_page_token).to eq('x')
          end
        end
      end

      context 'when status is supplied' do
        let(:api_completed_status) { Temporalio::Api::Enums::V1::WorkflowExecutionStatus::WORKFLOW_EXECUTION_STATUS_COMPLETED }

        it 'makes an API request' do
          subject.list_closed_workflow_executions(
            **args.merge(status: Temporal::Workflow::Status::COMPLETED)
          )

          expect(grpc_stub).to have_received(:list_closed_workflow_executions) do |request|
            expect(request).to be_an_instance_of(Temporalio::Api::WorkflowService::V1::ListClosedWorkflowExecutionsRequest)
            expect(request.status_filter).to eq(Temporalio::Api::Filter::V1::StatusFilter.new(status: api_completed_status))
          end
        end
      end

      context 'when workflow_id is supplied' do
        it 'makes an API request' do
          subject.list_closed_workflow_executions(**args.merge(workflow_id: 'xxx'))

          expect(grpc_stub).to have_received(:list_closed_workflow_executions) do |request|
            expect(request).to be_an_instance_of(Temporalio::Api::WorkflowService::V1::ListClosedWorkflowExecutionsRequest)
            expect(request.execution_filter)
              .to be_an_instance_of(Temporalio::Api::Filter::V1::WorkflowExecutionFilter)
            expect(request.execution_filter.workflow_id).to eq('xxx')
          end
        end
      end

      context 'when workflow is supplied' do
        it 'makes an API request' do
          subject.list_closed_workflow_executions(**args.merge(workflow: 'TestWorkflow'))

          expect(grpc_stub).to have_received(:list_closed_workflow_executions) do |request|
            expect(request).to be_an_instance_of(Temporalio::Api::WorkflowService::V1::ListClosedWorkflowExecutionsRequest)
            expect(request.type_filter).to be_an_instance_of(Temporalio::Api::Filter::V1::WorkflowTypeFilter)
            expect(request.type_filter.name).to eq('TestWorkflow')
          end
        end
      end
    end
  end

  describe '#respond_query_task_completed' do
    let(:task_token) { SecureRandom.uuid }

    before do
      allow(grpc_stub)
        .to receive(:respond_query_task_completed)
        .and_return(Temporalio::Api::WorkflowService::V1::RespondQueryTaskCompletedResponse.new)
    end

    context 'when query result is an answer' do
      let(:query_result) { Temporal::Workflow::QueryResult.answer(42) }

      it 'makes an API request' do
        subject.respond_query_task_completed(
          namespace: namespace,
          task_token: task_token,
          query_result: query_result
        )

        expect(grpc_stub).to have_received(:respond_query_task_completed) do |request|
          expect(request).to be_an_instance_of(Temporalio::Api::WorkflowService::V1::RespondQueryTaskCompletedRequest)
          expect(request.task_token).to eq(task_token)
          expect(request.namespace).to eq(namespace)
          expect(request.completed_type).to eq(Temporalio::Api::Enums::V1::QueryResultType.lookup(
            Temporalio::Api::Enums::V1::QueryResultType::QUERY_RESULT_TYPE_ANSWERED)
          )
          expect(request.query_result).to eq(TestDeserializer.to_query_payloads(42))
          expect(request.error_message).to eq('')
        end
      end
    end

    context 'when query result is a failure' do
      let(:query_result) { Temporal::Workflow::QueryResult.failure(StandardError.new('Test query failure')) }

      it 'makes an API request' do
        subject.respond_query_task_completed(
          namespace: namespace,
          task_token: task_token,
          query_result: query_result
        )

        expect(grpc_stub).to have_received(:respond_query_task_completed) do |request|
          expect(request).to be_an_instance_of(Temporalio::Api::WorkflowService::V1::RespondQueryTaskCompletedRequest)
          expect(request.task_token).to eq(task_token)
          expect(request.namespace).to eq(namespace)
          expect(request.completed_type).to eq(Temporalio::Api::Enums::V1::QueryResultType.lookup(
            Temporalio::Api::Enums::V1::QueryResultType::QUERY_RESULT_TYPE_FAILED)
          )
          expect(request.query_result).to eq(nil)
          expect(request.error_message).to eq('Test query failure')
        end
      end
    end
  end

  describe '#respond_workflow_task_completed' do
    let(:task_token) { SecureRandom.uuid }

    before do
      allow(grpc_stub)
        .to receive(:respond_workflow_task_completed)
        .and_return(Temporalio::Api::WorkflowService::V1::RespondWorkflowTaskCompletedResponse.new)
    end

    context 'when responding with query results' do
      let(:query_results) do
        {
          '1' => Temporal::Workflow::QueryResult.answer(42),
          '2' => Temporal::Workflow::QueryResult.failure(StandardError.new('Test query failure')),
        }
      end

      it 'makes an API request' do
        subject.respond_workflow_task_completed(
          namespace: namespace,
          task_token: task_token,
          commands: [],
          query_results: query_results,
          binary_checksum: binary_checksum,
          new_sdk_flags_used: [1]
        )

        expect(grpc_stub).to have_received(:respond_workflow_task_completed) do |request|
          expect(request).to be_an_instance_of(Temporalio::Api::WorkflowService::V1::RespondWorkflowTaskCompletedRequest)
          expect(request.task_token).to eq(task_token)
          expect(request.namespace).to eq(namespace)
          expect(request.commands).to be_empty
          expect(request.identity).to eq(identity)
          expect(request.binary_checksum).to eq(binary_checksum)

          expect(request.query_results.length).to eq(2)

          expect(request.query_results['1']).to be_a(Temporalio::Api::Query::V1::WorkflowQueryResult)
          expect(request.query_results['1'].result_type).to eq(Temporalio::Api::Enums::V1::QueryResultType.lookup(
            Temporalio::Api::Enums::V1::QueryResultType::QUERY_RESULT_TYPE_ANSWERED)
          )
          expect(request.query_results['1'].answer).to eq(TestDeserializer.to_query_payloads(42))

          expect(request.query_results['2']).to be_a(Temporalio::Api::Query::V1::WorkflowQueryResult)
          expect(request.query_results['2'].result_type).to eq(Temporalio::Api::Enums::V1::QueryResultType.lookup(
            Temporalio::Api::Enums::V1::QueryResultType::QUERY_RESULT_TYPE_FAILED)
          )
          expect(request.query_results['2'].error_message).to eq('Test query failure')

          expect(request.sdk_metadata.lang_used_flags).to eq([1])
        end
      end
    end
  end

  describe '#respond_workflow_task_failed' do
    let(:task_token) { 'task-token' }
    let(:cause) { Temporalio::Api::Enums::V1::WorkflowTaskFailedCause::WORKFLOW_TASK_FAILED_CAUSE_UNHANDLED_COMMAND }

    before { allow(grpc_stub).to receive(:respond_workflow_task_failed) }

    it 'calls GRPC service with supplied arguments' do
      subject.respond_workflow_task_failed(
        namespace: namespace,
        task_token: task_token,
        cause: cause,
        exception: Exception.new('something went wrong'),
        binary_checksum: binary_checksum
      )

      expect(grpc_stub).to have_received(:respond_workflow_task_failed) do |request|
        expect(request).to be_an_instance_of(Temporalio::Api::WorkflowService::V1::RespondWorkflowTaskFailedRequest)
        expect(request.namespace).to eq(namespace)
        expect(request.task_token).to eq(task_token)
        expect(request.cause).to be(Temporalio::Api::Enums::V1::WorkflowTaskFailedCause.lookup(cause))
        expect(request.identity).to eq(identity)
        expect(request.binary_checksum).to eq(binary_checksum)
      end
    end
  end

  describe '#add_custom_search_attributes' do
    it 'calls GRPC service with supplied arguments' do
      allow(grpc_operator_stub).to receive(:add_search_attributes)
      subject.add_custom_search_attributes(
        {
          'SomeTextField' => :text,
          'SomeKeywordField' => :keyword,
          'SomeIntField' => :int,
          'SomeDoubleField' => :double,
          'SomeBoolField' => :bool,
          'SomeDatetimeField' => :datetime,
          'SomeKeywordListField' => :keyword_list
        },
        namespace
      )

      expect(grpc_operator_stub).to have_received(:add_search_attributes) do |request|
        expect(request).to be_an_instance_of(Temporalio::Api::OperatorService::V1::AddSearchAttributesRequest)
        expect(request.search_attributes).to eq(
          {
            'SomeTextField' => Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_TEXT,
            'SomeKeywordField' => Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_KEYWORD,
            'SomeIntField' => Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_INT,
            'SomeDoubleField' => Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_DOUBLE,
            'SomeBoolField' => Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_BOOL,
            'SomeDatetimeField' => Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_DATETIME,
            'SomeKeywordListField' => Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_KEYWORD_LIST
          }
        )
        expect(request.namespace).to eq(namespace)
      end
    end

    it 'attribute already exists' do
      allow(grpc_operator_stub).to receive(:add_search_attributes).and_raise(GRPC::AlreadyExists.new(''))
      expect do
        subject.add_custom_search_attributes(
          {
            'SomeTextField' => :text
          },
          namespace
        )
      end.to raise_error(Temporal::SearchAttributeAlreadyExistsFailure)
    end

    it 'failed to add attribute' do
      allow(grpc_operator_stub).to receive(:add_search_attributes).and_raise(GRPC::Internal.new(''))
      expect do
        subject.add_custom_search_attributes(
          {
            'SomeTextField' => :text
          },
          namespace
        )
      end.to raise_error(Temporal::SearchAttributeFailure)
    end

    it 'attributes can be symbols' do
      allow(grpc_operator_stub).to receive(:add_search_attributes)
      subject.add_custom_search_attributes(
        {
          SomeTextField: :text
        },
        namespace
      )

      expect(grpc_operator_stub).to have_received(:add_search_attributes) do |request|
        expect(request).to be_an_instance_of(Temporalio::Api::OperatorService::V1::AddSearchAttributesRequest)
        expect(request.search_attributes).to eq(
          {
            'SomeTextField' => Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_TEXT
          }
        )
        expect(request.namespace).to eq(namespace)
      end
    end

    it 'invalid attribute type' do
      expect do
        subject.add_custom_search_attributes(
          {
            'SomeBadField' => :foo
          },
          namespace
        )
      end.to raise_error(Temporal::InvalidSearchAttributeTypeFailure) do |e|
        expect(e.to_s).to eq('Cannot add search attributes ({"SomeBadField"=>:foo}): unknown search attribute type :foo, supported types: [:text, :keyword, :int, :double, :bool, :datetime, :keyword_list]')
      end
    end
  end

  describe '#list_custom_search_attributes' do
    it 'calls GRPC service with supplied arguments' do
      allow(grpc_operator_stub).to receive(:list_search_attributes).and_return(
        Temporalio::Api::OperatorService::V1::ListSearchAttributesResponse.new(
          custom_attributes: {
            'SomeTextField' => Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_TEXT,
            'SomeKeywordField' => Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_KEYWORD,
            'SomeIntField' => Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_INT,
            'SomeDoubleField' => Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_DOUBLE,
            'SomeBoolField' => Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_BOOL,
            'SomeDatetimeField' => Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_DATETIME,
            'SomeKeywordListField' => Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_KEYWORD_LIST
          }
        )
      )

      response = subject.list_custom_search_attributes(namespace)

      expect(response).to eq(
        {
          'SomeTextField' => :text,
          'SomeKeywordField' => :keyword,
          'SomeIntField' => :int,
          'SomeDoubleField' => :double,
          'SomeBoolField' => :bool,
          'SomeDatetimeField' => :datetime,
          'SomeKeywordListField' => :keyword_list
        }
      )

      expect(grpc_operator_stub).to have_received(:list_search_attributes) do |request|
        expect(request).to be_an_instance_of(Temporalio::Api::OperatorService::V1::ListSearchAttributesRequest)
        expect(request.namespace).to eq(namespace)
      end
    end

    it 'unknown attribute type becomes nil' do
      allow(grpc_operator_stub).to receive(:list_search_attributes).and_return(
        Temporalio::Api::OperatorService::V1::ListSearchAttributesResponse.new(
          custom_attributes: {
            'SomeTextField' => Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_TEXT,
            'SomeUnknownField' => 100 # simulate some new type being added in the proto in the future
          }
        )
      )

      response = subject.list_custom_search_attributes(namespace)

      expect(response).to eq(
        {
          'SomeTextField' => :text,
          'SomeUnknownField' => nil
        }
      )
    end
  end

  describe '#remove_custom_search_attributes' do
    it 'calls GRPC service with supplied arguments' do
      allow(grpc_operator_stub).to receive(:remove_search_attributes)

      attributes = ['SomeTextField', 'SomeIntField']

      subject.remove_custom_search_attributes(attributes, namespace)

      expect(grpc_operator_stub).to have_received(:remove_search_attributes) do |request|
        expect(request).to be_an_instance_of(Temporalio::Api::OperatorService::V1::RemoveSearchAttributesRequest)
        expect(request.search_attributes).to eq(attributes)
        expect(request.namespace).to eq(namespace)
      end
    end

    it 'cannot remove non-existent attribute' do
      allow(grpc_operator_stub).to receive(:remove_search_attributes).and_raise(GRPC::NotFound.new)

      attributes = ['SomeTextField', 'SomeIntField']

      expect do
        subject.remove_custom_search_attributes(attributes, namespace)
      end.to raise_error(Temporal::NotFoundFailure)
    end

    it 'attribute names can be symbols' do
      allow(grpc_operator_stub).to receive(:remove_search_attributes)

      subject.remove_custom_search_attributes(%i[SomeTextField SomeIntField], namespace)

      expect(grpc_operator_stub).to have_received(:remove_search_attributes) do |request|
        expect(request).to be_an_instance_of(Temporalio::Api::OperatorService::V1::RemoveSearchAttributesRequest)
        expect(request.search_attributes).to eq(%w[SomeTextField SomeIntField])
      end
    end
  end

  describe "passing in options" do
    before do
      allow(subject).to receive(:client).and_call_original
    end

    context "when keepalive_time_ms is passed" do
      subject { Temporal::Connection::GRPC.new(nil, nil, identity, :this_channel_is_insecure, keepalive_time_ms: 30_000) }

      it "passes the option to the channel args" do
        expect(Temporalio::Api::WorkflowService::V1::WorkflowService::Stub).to receive(:new).with(
          ":",
          :this_channel_is_insecure,
          timeout: 60,
          interceptors: [instance_of(Temporal::Connection::ClientNameVersionInterceptor)],
          channel_args: {
            "grpc.keepalive_time_ms" => 30_000
          }
        )
        subject.send(:client)
      end
    end

    context "when passing retry_connection" do
      subject { Temporal::Connection::GRPC.new(nil, nil, identity, :this_channel_is_insecure, retry_connection: true) }

      it "passes the option to the channel args" do
        expect(Temporalio::Api::WorkflowService::V1::WorkflowService::Stub).to receive(:new).with(
          ":",
          :this_channel_is_insecure,
          timeout: 60,
          interceptors: [instance_of(Temporal::Connection::ClientNameVersionInterceptor)],
          channel_args: {
            "grpc.enable_retries" => 1,
            "grpc.service_config" => {
              methodConfig: [
                {
                  name: [
                    {
                      service: "temporal.api.workflowservice.v1.WorkflowService",
                    }
                  ],
                  retryPolicy: {
                    retryableStatusCodes: ["UNAVAILABLE"],
                    maxAttempts: 3,
                    initialBackoff: "0.1s",
                    backoffMultiplier: 2.0,
                    maxBackoff: "0.3s"
                  }
                }
              ]
            }.to_json
          }
        )
        subject.send(:client)
      end
    end
  end
end
