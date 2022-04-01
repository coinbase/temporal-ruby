require 'grpc'
require 'time'
require 'google/protobuf/well_known_types'
require 'securerandom'
require 'gen/temporal/api/filter/v1/message_pb'
require 'gen/temporal/api/workflowservice/v1/service_services_pb'
require 'gen/temporal/api/enums/v1/workflow_pb'
require 'temporal/connection/errors'
require 'temporal/connection/serializer'
require 'temporal/connection/serializer/failure'
require 'temporal/concerns/payloads'

module Temporal
  module Connection
    class GRPC
      include Concerns::Payloads

      WORKFLOW_ID_REUSE_POLICY = {
        allow_failed: Temporal::Api::Enums::V1::WorkflowIdReusePolicy::WORKFLOW_ID_REUSE_POLICY_ALLOW_DUPLICATE_FAILED_ONLY,
        allow: Temporal::Api::Enums::V1::WorkflowIdReusePolicy::WORKFLOW_ID_REUSE_POLICY_ALLOW_DUPLICATE,
        reject: Temporal::Api::Enums::V1::WorkflowIdReusePolicy::WORKFLOW_ID_REUSE_POLICY_REJECT_DUPLICATE
      }.freeze

      HISTORY_EVENT_FILTER = {
        all: Temporal::Api::Enums::V1::HistoryEventFilterType::HISTORY_EVENT_FILTER_TYPE_ALL_EVENT,
        close: Temporal::Api::Enums::V1::HistoryEventFilterType::HISTORY_EVENT_FILTER_TYPE_CLOSE_EVENT,
      }.freeze

      QUERY_REJECT_CONDITION = {
        none: Temporal::Api::Enums::V1::QueryRejectCondition::QUERY_REJECT_CONDITION_NONE,
        not_open: Temporal::Api::Enums::V1::QueryRejectCondition::QUERY_REJECT_CONDITION_NOT_OPEN,
        not_completed_cleanly: Temporal::Api::Enums::V1::QueryRejectCondition::QUERY_REJECT_CONDITION_NOT_COMPLETED_CLEANLY
      }.freeze

      DEFAULT_OPTIONS = {
        max_page_size: 100
      }.freeze

      def initialize(host, port, identity, options = {})
        @url = "#{host}:#{port}"
        @identity = identity
        @poll = true
        @poll_mutex = Mutex.new
        @poll_request = nil
        @options = DEFAULT_OPTIONS.merge(options)
      end

      def register_namespace(name:, description: nil, is_global: false, retention_period: 10, data: nil)
        request = Temporal::Api::WorkflowService::V1::RegisterNamespaceRequest.new(
          namespace: name,
          description: description,
          is_global_namespace: is_global,
          workflow_execution_retention_period: Google::Protobuf::Duration.new(
            seconds: (retention_period * 24 * 60 * 60).to_i
          ),
          data: data,
        )
        client.register_namespace(request)
      rescue ::GRPC::AlreadyExists => e
        raise Temporal::NamespaceAlreadyExistsFailure, e.details
      end

      def describe_namespace(name:)
        request = Temporal::Api::WorkflowService::V1::DescribeNamespaceRequest.new(namespace: name)
        client.describe_namespace(request)
      end

      def list_namespaces(page_size:, next_page_token: "")
        request = Temporal::Api::WorkflowService::V1::ListNamespacesRequest.new(page_size: page_size, next_page_token: next_page_token)
        client.list_namespaces(request)
      end

      def update_namespace(name:, description:)
        request = Temporal::Api::WorkflowService::V1::UpdateNamespaceRequest.new(
          namespace: name,
          update_info: Temporal::Api::WorkflowService::V1::UpdateNamespaceInfo.new(
            description: description
          )
        )
        client.update_namespace(request)
      end

      def deprecate_namespace(name:)
        request = Temporal::Api::WorkflowService::V1::DeprecateNamespaceRequest.new(namespace: name)
        client.deprecate_namespace(request)
      end

      def start_workflow_execution(
        namespace:,
        workflow_id:,
        workflow_name:,
        task_queue:,
        input: nil,
        execution_timeout:,
        run_timeout:,
        task_timeout:,
        workflow_id_reuse_policy: nil,
        headers: nil,
        cron_schedule: nil,
        memo: nil
      )
        request = Temporal::Api::WorkflowService::V1::StartWorkflowExecutionRequest.new(
          identity: identity,
          namespace: namespace,
          workflow_type: Temporal::Api::Common::V1::WorkflowType.new(
            name: workflow_name
          ),
          workflow_id: workflow_id,
          task_queue: Temporal::Api::TaskQueue::V1::TaskQueue.new(
            name: task_queue
          ),
          input: to_payloads(input),
          workflow_execution_timeout: execution_timeout,
          workflow_run_timeout: run_timeout,
          workflow_task_timeout: task_timeout,
          request_id: SecureRandom.uuid,
          header: Temporal::Api::Common::V1::Header.new(
            fields: to_payload_map(headers || {})
          ),
          cron_schedule: cron_schedule,
          memo: Temporal::Api::Common::V1::Memo.new(
            fields: to_payload_map(memo || {})
          )
        )

        if workflow_id_reuse_policy
          policy = WORKFLOW_ID_REUSE_POLICY[workflow_id_reuse_policy]
          raise Client::ArgumentError, 'Unknown workflow_id_reuse_policy specified' unless policy

          request.workflow_id_reuse_policy = policy
        end

        client.start_workflow_execution(request)
      rescue ::GRPC::AlreadyExists => e
        # Feel like there should be cleaner way to do this...
        run_id = e.details[/RunId: ([a-f0-9]+-[a-f0-9]+-[a-f0-9]+-[a-f0-9]+-[a-f0-9]+)/, 1]
        raise Temporal::WorkflowExecutionAlreadyStartedFailure.new(e.details, run_id)
      end

      SERVER_MAX_GET_WORKFLOW_EXECUTION_HISTORY_POLL = 30

      def get_workflow_execution_history(
        namespace:,
        workflow_id:,
        run_id:,
        next_page_token: nil,
        wait_for_new_event: false,
        event_type: :all,
        timeout: nil
      )
        if wait_for_new_event
          if timeout.nil?
            # This is an internal error.  Wrappers should enforce this.
            raise "You must specify a timeout when wait_for_new_event = true."
          elsif timeout > SERVER_MAX_GET_WORKFLOW_EXECUTION_HISTORY_POLL
            raise ClientError.new(
              "You may not specify a timeout of more than #{SERVER_MAX_GET_WORKFLOW_EXECUTION_HISTORY_POLL} seconds, got: #{timeout}."
            )
          end
        end
        request = Temporal::Api::WorkflowService::V1::GetWorkflowExecutionHistoryRequest.new(
          namespace: namespace,
          execution: Temporal::Api::Common::V1::WorkflowExecution.new(
            workflow_id: workflow_id,
            run_id: run_id
          ),
          next_page_token: next_page_token,
          wait_new_event: wait_for_new_event,
          history_event_filter_type: HISTORY_EVENT_FILTER[event_type]
        )
        deadline = timeout ? Time.now + timeout : nil
        client.get_workflow_execution_history(request, deadline: deadline)
      end

      def poll_workflow_task_queue(namespace:, task_queue:)
        request = Temporal::Api::WorkflowService::V1::PollWorkflowTaskQueueRequest.new(
          identity: identity,
          namespace: namespace,
          task_queue: Temporal::Api::TaskQueue::V1::TaskQueue.new(
            name: task_queue
          )
        )

        poll_mutex.synchronize do
          return unless can_poll?
          @poll_request = client.poll_workflow_task_queue(request, return_op: true)
        end

        poll_request.execute
      end

      def respond_query_task_completed(namespace:, task_token:, query_result:)
        query_result_proto = Serializer.serialize(query_result)
        request = Temporal::Api::WorkflowService::V1::RespondQueryTaskCompletedRequest.new(
          task_token: task_token,
          namespace: namespace,
          completed_type: query_result_proto.result_type,
          query_result: query_result_proto.answer,
          error_message: query_result_proto.error_message,
        )

        client.respond_query_task_completed(request)
      end

      def respond_workflow_task_completed(namespace:, task_token:, commands:, query_results: {})
        request = Temporal::Api::WorkflowService::V1::RespondWorkflowTaskCompletedRequest.new(
          namespace: namespace,
          identity: identity,
          task_token: task_token,
          commands: Array(commands).map { |(_, command)| Serializer.serialize(command) },
          query_results: query_results.transform_values { |value| Serializer.serialize(value) }
        )

        client.respond_workflow_task_completed(request)
      end

      def respond_workflow_task_failed(namespace:, task_token:, cause:, exception: nil)
        request = Temporal::Api::WorkflowService::V1::RespondWorkflowTaskFailedRequest.new(
          namespace: namespace,
          identity: identity,
          task_token: task_token,
          cause: cause,
          failure: Serializer::Failure.new(exception).to_proto
        )
        client.respond_workflow_task_failed(request)
      end

      def poll_activity_task_queue(namespace:, task_queue:)
        request = Temporal::Api::WorkflowService::V1::PollActivityTaskQueueRequest.new(
          identity: identity,
          namespace: namespace,
          task_queue: Temporal::Api::TaskQueue::V1::TaskQueue.new(
            name: task_queue
          )
        )

        poll_mutex.synchronize do
          return unless can_poll?
          @poll_request = client.poll_activity_task_queue(request, return_op: true)
        end

        poll_request.execute
      end

      def record_activity_task_heartbeat(namespace:, task_token:, details: nil)
        request = Temporal::Api::WorkflowService::V1::RecordActivityTaskHeartbeatRequest.new(
          namespace: namespace,
          task_token: task_token,
          details: to_details_payloads(details),
          identity: identity
        )
        client.record_activity_task_heartbeat(request)
      end

      def record_activity_task_heartbeat_by_id
        raise NotImplementedError
      end

      def respond_activity_task_completed(namespace:, task_token:, result:)
        request = Temporal::Api::WorkflowService::V1::RespondActivityTaskCompletedRequest.new(
          namespace: namespace,
          identity: identity,
          task_token: task_token,
          result: to_result_payloads(result),
        )
        client.respond_activity_task_completed(request)
      end

      def respond_activity_task_completed_by_id(namespace:, activity_id:, workflow_id:, run_id:, result:)
        request = Temporal::Api::WorkflowService::V1::RespondActivityTaskCompletedByIdRequest.new(
          identity: identity,
          namespace: namespace,
          workflow_id: workflow_id,
          run_id: run_id,
          activity_id: activity_id,
          result: to_result_payloads(result)
        )
        client.respond_activity_task_completed_by_id(request)
      end

      def respond_activity_task_failed(namespace:, task_token:, exception:)
        request = Temporal::Api::WorkflowService::V1::RespondActivityTaskFailedRequest.new(
          namespace: namespace,
          identity: identity,
          task_token: task_token,
          failure: Serializer::Failure.new(exception).to_proto
        )
        client.respond_activity_task_failed(request)
      end

      def respond_activity_task_failed_by_id(namespace:, activity_id:, workflow_id:, run_id:, exception:)
        request = Temporal::Api::WorkflowService::V1::RespondActivityTaskFailedByIdRequest.new(
          identity: identity,
          namespace: namespace,
          workflow_id: workflow_id,
          run_id: run_id,
          activity_id: activity_id,
          failure: Serializer::Failure.new(exception).to_proto
        )
        client.respond_activity_task_failed_by_id(request)
      end

      def respond_activity_task_canceled(namespace:, task_token:, details: nil)
        request = Temporal::Api::WorkflowService::V1::RespondActivityTaskCanceledRequest.new(
          namespace: namespace,
          task_token: task_token,
          details: to_details_payloads(details),
          identity: identity
        )
        client.respond_activity_task_canceled(request)
      end

      def respond_activity_task_canceled_by_id
        raise NotImplementedError
      end

      def request_cancel_workflow_execution
        raise NotImplementedError
      end

      def signal_workflow_execution(namespace:, workflow_id:, run_id:, signal:, input: nil)
        request = Temporal::Api::WorkflowService::V1::SignalWorkflowExecutionRequest.new(
          namespace: namespace,
          workflow_execution: Temporal::Api::Common::V1::WorkflowExecution.new(
            workflow_id: workflow_id,
            run_id: run_id
          ),
          signal_name: signal,
          input: to_signal_payloads(input),
          identity: identity
        )
        client.signal_workflow_execution(request)
      end

      def signal_with_start_workflow_execution(
        namespace:,
        workflow_id:,
        workflow_name:,
        task_queue:,
        input: nil,
        execution_timeout:,
        run_timeout:,
        task_timeout:,
        workflow_id_reuse_policy: nil,
        headers: nil,
        cron_schedule: nil,
        signal_name:,
        signal_input:,
        memo: nil
      )
        proto_header_fields = if headers.nil?
            to_payload_map({})
        elsif headers.class == Hash
            to_payload_map(headers)
        else
          # Preserve backward compatability for headers specified using proto objects
          warn '[DEPRECATION] Specify headers using a hash rather than protobuf objects'
          headers
        end

        request = Temporal::Api::WorkflowService::V1::SignalWithStartWorkflowExecutionRequest.new(
          identity: identity,
          namespace: namespace,
          workflow_type: Temporal::Api::Common::V1::WorkflowType.new(
            name: workflow_name
          ),
          workflow_id: workflow_id,
          task_queue: Temporal::Api::TaskQueue::V1::TaskQueue.new(
            name: task_queue
          ),
          input: to_payloads(input),
          workflow_execution_timeout: execution_timeout,
          workflow_run_timeout: run_timeout,
          workflow_task_timeout: task_timeout,
          request_id: SecureRandom.uuid,
          header: Temporal::Api::Common::V1::Header.new(
            fields: proto_header_fields,
          ),
          cron_schedule: cron_schedule,
          signal_name: signal_name,
          signal_input: to_signal_payloads(signal_input),
          memo: Temporal::Api::Common::V1::Memo.new(
            fields: to_payload_map(memo || {})
          ),
        )

        if workflow_id_reuse_policy
          policy = WORKFLOW_ID_REUSE_POLICY[workflow_id_reuse_policy]
          raise Client::ArgumentError, 'Unknown workflow_id_reuse_policy specified' unless policy

          request.workflow_id_reuse_policy = policy
        end

        client.signal_with_start_workflow_execution(request)
      end

      def reset_workflow_execution(namespace:, workflow_id:, run_id:, reason:, workflow_task_event_id:)
        request = Temporal::Api::WorkflowService::V1::ResetWorkflowExecutionRequest.new(
          namespace: namespace,
          workflow_execution: Temporal::Api::Common::V1::WorkflowExecution.new(
            workflow_id: workflow_id,
            run_id: run_id,
          ),
          reason: reason,
          workflow_task_finish_event_id: workflow_task_event_id
        )
        client.reset_workflow_execution(request)
      end

      def terminate_workflow_execution(
        namespace:,
        workflow_id:,
        run_id:,
        reason: nil,
        details: nil
      )
        request = Temporal::Api::WorkflowService::V1::TerminateWorkflowExecutionRequest.new(
          identity: identity,
          namespace: namespace,
          workflow_execution: Temporal::Api::Common::V1::WorkflowExecution.new(
            workflow_id: workflow_id,
            run_id: run_id,
          ),
          reason: reason,
          details: to_details_payloads(details)
        )

        client.terminate_workflow_execution(request)
      end

      def list_open_workflow_executions(namespace:, from:, to:, next_page_token: nil, workflow_id: nil, workflow: nil)
        request = Temporal::Api::WorkflowService::V1::ListOpenWorkflowExecutionsRequest.new(
          namespace: namespace,
          maximum_page_size: options[:max_page_size],
          next_page_token: next_page_token,
          start_time_filter: serialize_time_filter(from, to),
          execution_filter: serialize_execution_filter(workflow_id),
          type_filter: serialize_type_filter(workflow)
        )
        client.list_open_workflow_executions(request)
      end

      def list_closed_workflow_executions(namespace:, from:, to:, next_page_token: nil, workflow_id: nil, workflow: nil, status: nil)
        request = Temporal::Api::WorkflowService::V1::ListClosedWorkflowExecutionsRequest.new(
          namespace: namespace,
          maximum_page_size: options[:max_page_size],
          next_page_token: next_page_token,
          start_time_filter: serialize_time_filter(from, to),
          execution_filter: serialize_execution_filter(workflow_id),
          type_filter: serialize_type_filter(workflow),
          status_filter: serialize_status_filter(status)
        )
        client.list_closed_workflow_executions(request)
      end

      def list_workflow_executions
        raise NotImplementedError
      end

      def list_archived_workflow_executions
        raise NotImplementedError
      end

      def scan_workflow_executions
        raise NotImplementedError
      end

      def count_workflow_executions
        raise NotImplementedError
      end

      def get_search_attributes
        raise NotImplementedError
      end

      def reset_sticky_task_queue
        raise NotImplementedError
      end

      def query_workflow(namespace:, workflow_id:, run_id:, query:, args: nil, query_reject_condition: nil)
        request = Temporal::Api::WorkflowService::V1::QueryWorkflowRequest.new(
          namespace: namespace,
          execution: Temporal::Api::Common::V1::WorkflowExecution.new(
            workflow_id: workflow_id,
            run_id: run_id
          ),
          query: Temporal::Api::Query::V1::WorkflowQuery.new(
            query_type: query,
            query_args: to_query_payloads(args)
          )
        )
        if query_reject_condition
          condition = QUERY_REJECT_CONDITION[query_reject_condition]
          raise Client::ArgumentError, 'Unknown query_reject_condition specified' unless condition

          request.query_reject_condition = condition
        end

        begin
          response = client.query_workflow(request)
        rescue ::GRPC::InvalidArgument => e
          raise Temporal::QueryFailedFailure, e.details
        end

        if response.query_rejected
          rejection_status = response.query_rejected.status || 'not specified by server'
          raise Temporal::QueryFailedFailure, "Query rejected: status #{rejection_status}"
        elsif !response.query_result
          raise Temporal::QueryFailedFailure, 'Invalid response from server'
        else
          from_query_payloads(response.query_result)
        end
      end

      def describe_workflow_execution(namespace:, workflow_id:, run_id:)
        request = Temporal::Api::WorkflowService::V1::DescribeWorkflowExecutionRequest.new(
          namespace: namespace,
          execution: Temporal::Api::Common::V1::WorkflowExecution.new(
            workflow_id: workflow_id,
            run_id: run_id
          )
        )
        client.describe_workflow_execution(request)
      end

      def describe_task_queue(namespace:, task_queue:)
        request = Temporal::Api::WorkflowService::V1::DescribeTaskQueueRequest.new(
          namespace: namespace,
          task_queue: Temporal::Api::TaskQueue::V1::TaskQueue.new(
            name: task_queue
          ),
          task_queue_type: Temporal::Api::Enums::V1::TaskQueueType::Workflow,
          include_task_queue_status: true
        )
        client.describe_task_queue(request)
      end

      def cancel_polling_request
        poll_mutex.synchronize do
          @poll = false
          poll_request&.cancel
        end
      end

      private

      attr_reader :url, :identity, :options, :poll_mutex, :poll_request

      def client
        @client ||= Temporal::Api::WorkflowService::V1::WorkflowService::Stub.new(
          url,
          :this_channel_is_insecure,
          timeout: 60
        )
      end

      def can_poll?
        @poll
      end

      def serialize_time_filter(from, to)
        Temporal::Api::Filter::V1::StartTimeFilter.new(
          earliest_time: from&.to_time,
          latest_time: to&.to_time
        )
      end

      def serialize_execution_filter(value)
        return unless value

        Temporal::Api::Filter::V1::WorkflowExecutionFilter.new(workflow_id: value)
      end

      def serialize_type_filter(value)
        return unless value

        Temporal::Api::Filter::V1::WorkflowTypeFilter.new(name: value)
      end

      def serialize_status_filter(value)
        return unless value

        sym = Temporal::Workflow::Status::API_STATUS_MAP.invert[value]
        status = Temporal::Api::Enums::V1::WorkflowExecutionStatus.resolve(sym)

        Temporal::Api::Filter::V1::StatusFilter.new(status: status)
      end
    end
  end
end
