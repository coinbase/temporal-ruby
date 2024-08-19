require 'grpc'
require 'time'
require 'google/protobuf/well_known_types'
require 'securerandom'
require 'json'
require 'gen/temporal/api/filter/v1/message_pb'
require 'gen/temporal/api/workflowservice/v1/service_services_pb'
require 'gen/temporal/api/operatorservice/v1/service_services_pb'
require 'gen/temporal/api/enums/v1/workflow_pb'
require 'gen/temporal/api/enums/v1/common_pb'
require 'temporal/connection/errors'
require 'temporal/connection/interceptors/client_name_version_interceptor'
require 'temporal/connection/serializer'
require 'temporal/connection/serializer/failure'
require 'temporal/connection/serializer/backfill'
require 'temporal/connection/serializer/schedule'
require 'temporal/connection/serializer/workflow_id_reuse_policy'
require 'temporal/concerns/payloads'

module Temporal
  module Connection
    class GRPC
      HISTORY_EVENT_FILTER = {
        all: Temporalio::Api::Enums::V1::HistoryEventFilterType::HISTORY_EVENT_FILTER_TYPE_ALL_EVENT,
        close: Temporalio::Api::Enums::V1::HistoryEventFilterType::HISTORY_EVENT_FILTER_TYPE_CLOSE_EVENT
      }.freeze

      QUERY_REJECT_CONDITION = {
        none: Temporalio::Api::Enums::V1::QueryRejectCondition::QUERY_REJECT_CONDITION_NONE,
        not_open: Temporalio::Api::Enums::V1::QueryRejectCondition::QUERY_REJECT_CONDITION_NOT_OPEN,
        not_completed_cleanly: Temporalio::Api::Enums::V1::QueryRejectCondition::QUERY_REJECT_CONDITION_NOT_COMPLETED_CLEANLY
      }.freeze

      SYMBOL_TO_INDEXED_VALUE_TYPE = {
        text: Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_TEXT,
        keyword: Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_KEYWORD,
        int: Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_INT,
        double: Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_DOUBLE,
        bool: Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_BOOL,
        datetime: Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_DATETIME,
        keyword_list: Temporalio::Api::Enums::V1::IndexedValueType::INDEXED_VALUE_TYPE_KEYWORD_LIST
      }.freeze

      INDEXED_VALUE_TYPE_TO_SYMBOL = SYMBOL_TO_INDEXED_VALUE_TYPE.map do |symbol, int_value|
        [Temporalio::Api::Enums::V1::IndexedValueType.lookup(int_value), symbol]
      end.to_h.freeze

      SYMBOL_TO_RESET_REAPPLY_TYPE = {
        signal: Temporalio::Api::Enums::V1::ResetReapplyType::RESET_REAPPLY_TYPE_SIGNAL,
        none: Temporalio::Api::Enums::V1::ResetReapplyType::RESET_REAPPLY_TYPE_NONE
      }

      DEFAULT_OPTIONS = {
        max_page_size: 100
      }.freeze

      CONNECTION_TIMEOUT_SECONDS = 60

      def initialize(host, port, identity, credentials, converter, options = {})
        @url = "#{host}:#{port}"
        @identity = identity
        @credentials = credentials
        @converter = converter
        @poll = true
        @poll_mutex = Mutex.new
        @poll_request = nil
        @options = DEFAULT_OPTIONS.merge(options)
      end

      def register_namespace(name:, description: nil, is_global: false, retention_period: 10, data: nil)
        request = Temporalio::Api::WorkflowService::V1::RegisterNamespaceRequest.new(
          namespace: name,
          description: description,
          is_global_namespace: is_global,
          workflow_execution_retention_period: Google::Protobuf::Duration.new(
            seconds: (retention_period * 24 * 60 * 60).to_i
          ),
          data: data
        )
        client.register_namespace(request)
      rescue ::GRPC::AlreadyExists => e
        raise Temporal::NamespaceAlreadyExistsFailure, e.details
      end

      def describe_namespace(name:)
        request = Temporalio::Api::WorkflowService::V1::DescribeNamespaceRequest.new(namespace: name)
        client.describe_namespace(request)
      end

      def list_namespaces(page_size:, next_page_token: '')
        request = Temporalio::Api::WorkflowService::V1::ListNamespacesRequest.new(page_size: page_size,
                                                                                  next_page_token: next_page_token)
        client.list_namespaces(request)
      end

      def update_namespace(name:, description:)
        request = Temporalio::Api::WorkflowService::V1::UpdateNamespaceRequest.new(
          namespace: name,
          update_info: Temporalio::Api::WorkflowService::V1::UpdateNamespaceInfo.new(
            description: description
          )
        )
        client.update_namespace(request)
      end

      def deprecate_namespace(name:)
        request = Temporalio::Api::WorkflowService::V1::DeprecateNamespaceRequest.new(namespace: name)
        client.deprecate_namespace(request)
      end

      def start_workflow_execution(
        namespace:,
        workflow_id:,
        workflow_name:,
        task_queue:,
        execution_timeout:,
        run_timeout:,
        task_timeout:,
        input: nil,
        workflow_id_reuse_policy: nil,
        headers: nil,
        cron_schedule: nil,
        memo: nil,
        search_attributes: nil
      )
        request = Temporalio::Api::WorkflowService::V1::StartWorkflowExecutionRequest.new(
          identity: identity,
          namespace: namespace,
          workflow_type: Temporalio::Api::Common::V1::WorkflowType.new(
            name: workflow_name
          ),
          workflow_id: workflow_id,
          workflow_id_reuse_policy: Temporal::Connection::Serializer::WorkflowIdReusePolicy.new(workflow_id_reuse_policy, converter).to_proto,
          task_queue: Temporalio::Api::TaskQueue::V1::TaskQueue.new(
            name: task_queue
          ),
          input: converter.to_payloads(input),
          workflow_execution_timeout: execution_timeout,
          workflow_run_timeout: run_timeout,
          workflow_task_timeout: task_timeout,
          request_id: SecureRandom.uuid,
          header: Temporalio::Api::Common::V1::Header.new(
            fields: converter.to_payload_map(headers || {})
          ),
          cron_schedule: cron_schedule,
          memo: Temporalio::Api::Common::V1::Memo.new(
            fields: converter.to_payload_map(memo || {})
          ),
          search_attributes: Temporalio::Api::Common::V1::SearchAttributes.new(
            indexed_fields: converter.to_payload_map_without_codec(search_attributes || {})
          )
        )

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
            raise 'You must specify a timeout when wait_for_new_event = true.'
          elsif timeout > SERVER_MAX_GET_WORKFLOW_EXECUTION_HISTORY_POLL
            raise ClientError,
                  "You may not specify a timeout of more than #{SERVER_MAX_GET_WORKFLOW_EXECUTION_HISTORY_POLL} seconds, got: #{timeout}."
          end
        end
        request = Temporalio::Api::WorkflowService::V1::GetWorkflowExecutionHistoryRequest.new(
          namespace: namespace,
          execution: Temporalio::Api::Common::V1::WorkflowExecution.new(
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

      def poll_workflow_task_queue(namespace:, task_queue:, binary_checksum:)
        request = Temporalio::Api::WorkflowService::V1::PollWorkflowTaskQueueRequest.new(
          identity: identity,
          namespace: namespace,
          task_queue: Temporalio::Api::TaskQueue::V1::TaskQueue.new(
            name: task_queue
          ),
          binary_checksum: binary_checksum
        )

        poll_mutex.synchronize do
          return unless can_poll?

          @poll_request = client.poll_workflow_task_queue(request, return_op: true)
        end

        poll_request.execute
      end

      def respond_query_task_completed(namespace:, task_token:, query_result:)
        query_result_proto = Serializer.serialize(query_result, converter)
        request = Temporalio::Api::WorkflowService::V1::RespondQueryTaskCompletedRequest.new(
          task_token: task_token,
          namespace: namespace,
          completed_type: query_result_proto.result_type,
          query_result: query_result_proto.answer,
          error_message: query_result_proto.error_message
        )

        client.respond_query_task_completed(request)
      end

      def respond_workflow_task_completed(namespace:, task_token:, commands:, binary_checksum:, new_sdk_flags_used:, query_results: {})
        request = Temporalio::Api::WorkflowService::V1::RespondWorkflowTaskCompletedRequest.new(
          namespace: namespace,
          identity: identity,
          task_token: task_token,
          commands: Array(commands).map { |(_, command)| Serializer.serialize(command, converter) },
          query_results: query_results.transform_values { |value| Serializer.serialize(value, converter) },
          binary_checksum: binary_checksum,
          sdk_metadata: if new_sdk_flags_used.any?
                          Temporalio::Api::Sdk::V1::WorkflowTaskCompletedMetadata.new(
                            lang_used_flags: new_sdk_flags_used.to_a
                          )
                          # else nil
                        end
        )

        client.respond_workflow_task_completed(request)
      end

      def respond_workflow_task_failed(namespace:, task_token:, cause:, exception:, binary_checksum:)
        request = Temporalio::Api::WorkflowService::V1::RespondWorkflowTaskFailedRequest.new(
          namespace: namespace,
          identity: identity,
          task_token: task_token,
          cause: cause,
          failure: Serializer::Failure.new(exception, converter).to_proto,
          binary_checksum: binary_checksum
        )
        client.respond_workflow_task_failed(request)
      end

      def poll_activity_task_queue(namespace:, task_queue:, max_tasks_per_second: 0)
        request = Temporalio::Api::WorkflowService::V1::PollActivityTaskQueueRequest.new(
          identity: identity,
          namespace: namespace,
          task_queue: Temporalio::Api::TaskQueue::V1::TaskQueue.new(
            name: task_queue
          )
        )

        if max_tasks_per_second > 0
          request.task_queue_metadata = Temporalio::Api::TaskQueue::V1::TaskQueueMetadata.new(
            max_tasks_per_second: Google::Protobuf::DoubleValue.new(value: max_tasks_per_second)
          )
        end

        poll_mutex.synchronize do
          return unless can_poll?

          @poll_request = client.poll_activity_task_queue(request, return_op: true)
        end

        poll_request.execute
      end

      def record_activity_task_heartbeat(namespace:, task_token:, details: nil)
        request = Temporalio::Api::WorkflowService::V1::RecordActivityTaskHeartbeatRequest.new(
          namespace: namespace,
          task_token: task_token,
          details: converter.to_details_payloads(details),
          identity: identity
        )
        client.record_activity_task_heartbeat(request)
      end

      def record_activity_task_heartbeat_by_id
        raise NotImplementedError
      end

      def respond_activity_task_completed(namespace:, task_token:, result:)
        request = Temporalio::Api::WorkflowService::V1::RespondActivityTaskCompletedRequest.new(
          namespace: namespace,
          identity: identity,
          task_token: task_token,
          result: converter.to_result_payloads(result)
        )
        client.respond_activity_task_completed(request)
      end

      def respond_activity_task_completed_by_id(namespace:, activity_id:, workflow_id:, run_id:, result:)
        request = Temporalio::Api::WorkflowService::V1::RespondActivityTaskCompletedByIdRequest.new(
          identity: identity,
          namespace: namespace,
          workflow_id: workflow_id,
          run_id: run_id,
          activity_id: activity_id,
          result: converter.to_result_payloads(result)
        )
        client.respond_activity_task_completed_by_id(request)
      end

      def respond_activity_task_failed(namespace:, task_token:, exception:)
        serialize_whole_error = options.fetch(:use_error_serialization_v2, Temporal.configuration.use_error_serialization_v2)
        request = Temporalio::Api::WorkflowService::V1::RespondActivityTaskFailedRequest.new(
          namespace: namespace,
          identity: identity,
          task_token: task_token,
          failure: Serializer::Failure.new(exception, converter, serialize_whole_error: serialize_whole_error).to_proto
        )
        client.respond_activity_task_failed(request)
      end

      def respond_activity_task_failed_by_id(namespace:, activity_id:, workflow_id:, run_id:, exception:)
        request = Temporalio::Api::WorkflowService::V1::RespondActivityTaskFailedByIdRequest.new(
          identity: identity,
          namespace: namespace,
          workflow_id: workflow_id,
          run_id: run_id,
          activity_id: activity_id,
          failure: Serializer::Failure.new(exception, converter).to_proto
        )
        client.respond_activity_task_failed_by_id(request)
      end

      def respond_activity_task_canceled(namespace:, task_token:, details: nil)
        request = Temporalio::Api::WorkflowService::V1::RespondActivityTaskCanceledRequest.new(
          namespace: namespace,
          task_token: task_token,
          details: converter.to_details_payloads(details),
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
        request = Temporalio::Api::WorkflowService::V1::SignalWorkflowExecutionRequest.new(
          namespace: namespace,
          workflow_execution: Temporalio::Api::Common::V1::WorkflowExecution.new(
            workflow_id: workflow_id,
            run_id: run_id
          ),
          signal_name: signal,
          input: converter.to_signal_payloads(input),
          identity: identity
        )
        client.signal_workflow_execution(request)
      end

      def signal_with_start_workflow_execution(
        namespace:,
        workflow_id:,
        workflow_name:,
        task_queue:,
        execution_timeout:, run_timeout:, task_timeout:, signal_name:, signal_input:, input: nil,
        workflow_id_reuse_policy: nil,
        headers: nil,
        cron_schedule: nil,
        memo: nil,
        search_attributes: nil
      )
        proto_header_fields = if headers.nil?
                                converter.to_payload_map({})
                              elsif headers.instance_of?(Hash)
                                converter.to_payload_map(headers)
                              else
                                # Preserve backward compatability for headers specified using proto objects
                                warn '[DEPRECATION] Specify headers using a hash rather than protobuf objects'
                                headers
                              end

        request = Temporalio::Api::WorkflowService::V1::SignalWithStartWorkflowExecutionRequest.new(
          identity: identity,
          namespace: namespace,
          workflow_type: Temporalio::Api::Common::V1::WorkflowType.new(
            name: workflow_name
          ),
          workflow_id: workflow_id,
          workflow_id_reuse_policy: Temporal::Connection::Serializer::WorkflowIdReusePolicy.new(workflow_id_reuse_policy, converter).to_proto,
          task_queue: Temporalio::Api::TaskQueue::V1::TaskQueue.new(
            name: task_queue
          ),
          input: converter.to_payloads(input),
          workflow_execution_timeout: execution_timeout,
          workflow_run_timeout: run_timeout,
          workflow_task_timeout: task_timeout,
          request_id: SecureRandom.uuid,
          header: Temporalio::Api::Common::V1::Header.new(
            fields: proto_header_fields
          ),
          cron_schedule: cron_schedule,
          signal_name: signal_name,
          signal_input: converter.to_signal_payloads(signal_input),
          memo: Temporalio::Api::Common::V1::Memo.new(
            fields: converter.to_payload_map(memo || {})
          ),
          search_attributes: Temporalio::Api::Common::V1::SearchAttributes.new(
            indexed_fields: converter.to_payload_map_without_codec(search_attributes || {})
          )
        )

        client.signal_with_start_workflow_execution(request)
      end

      def reset_workflow_execution(namespace:, workflow_id:, run_id:, reason:, workflow_task_event_id:, request_id:, reset_reapply_type: Temporal::ResetReapplyType::SIGNAL)
        request = Temporalio::Api::WorkflowService::V1::ResetWorkflowExecutionRequest.new(
          namespace: namespace,
          workflow_execution: Temporalio::Api::Common::V1::WorkflowExecution.new(
            workflow_id: workflow_id,
            run_id: run_id
          ),
          reason: reason,
          workflow_task_finish_event_id: workflow_task_event_id,
          request_id: request_id
        )

        if reset_reapply_type
          reapply_type = SYMBOL_TO_RESET_REAPPLY_TYPE[reset_reapply_type]
          raise Client::ArgumentError, 'Unknown reset_reapply_type specified' unless reapply_type

          request.reset_reapply_type = reapply_type
        end

        client.reset_workflow_execution(request)
      end

      def terminate_workflow_execution(
        namespace:,
        workflow_id:,
        run_id:,
        reason: nil,
        details: nil
      )
        request = Temporalio::Api::WorkflowService::V1::TerminateWorkflowExecutionRequest.new(
          identity: identity,
          namespace: namespace,
          workflow_execution: Temporalio::Api::Common::V1::WorkflowExecution.new(
            workflow_id: workflow_id,
            run_id: run_id
          ),
          reason: reason,
          details: converter.to_details_payloads(details)
        )

        client.terminate_workflow_execution(request)
      end

      def list_open_workflow_executions(namespace:, from:, to:, next_page_token: nil, workflow_id: nil, workflow: nil, max_page_size: nil)
        request = Temporalio::Api::WorkflowService::V1::ListOpenWorkflowExecutionsRequest.new(
          namespace: namespace,
          maximum_page_size: max_page_size.nil? ? options[:max_page_size] : max_page_size,
          next_page_token: next_page_token,
          start_time_filter: serialize_time_filter(from, to),
          execution_filter: serialize_execution_filter(workflow_id),
          type_filter: serialize_type_filter(workflow)
        )
        client.list_open_workflow_executions(request)
      end

      def list_closed_workflow_executions(namespace:, from:, to:, next_page_token: nil, workflow_id: nil, workflow: nil, status: nil, max_page_size: nil)
        request = Temporalio::Api::WorkflowService::V1::ListClosedWorkflowExecutionsRequest.new(
          namespace: namespace,
          maximum_page_size: max_page_size.nil? ? options[:max_page_size] : max_page_size,
          next_page_token: next_page_token,
          start_time_filter: serialize_time_filter(from, to),
          execution_filter: serialize_execution_filter(workflow_id),
          type_filter: serialize_type_filter(workflow),
          status_filter: serialize_status_filter(status)
        )
        client.list_closed_workflow_executions(request)
      end

      def list_workflow_executions(namespace:, query:, next_page_token: nil, max_page_size: nil)
        request = Temporalio::Api::WorkflowService::V1::ListWorkflowExecutionsRequest.new(
          namespace: namespace,
          page_size: max_page_size.nil? ? options[:max_page_size] : max_page_size,
          next_page_token: next_page_token,
          query: query
        )
        client.list_workflow_executions(request)
      end

      def list_archived_workflow_executions
        raise NotImplementedError
      end

      def scan_workflow_executions
        raise NotImplementedError
      end

      def count_workflow_executions(namespace:, query:)
        request = Temporalio::Api::WorkflowService::V1::CountWorkflowExecutionsRequest.new(
          namespace: namespace,
          query: query
        )
        client.count_workflow_executions(request)
      end

      def add_custom_search_attributes(attributes, namespace)
        attributes.each_value do |symbol_type|
          next if SYMBOL_TO_INDEXED_VALUE_TYPE.include?(symbol_type)

          raise Temporal::InvalidSearchAttributeTypeFailure,
                "Cannot add search attributes (#{attributes}): unknown search attribute type :#{symbol_type}, supported types: #{SYMBOL_TO_INDEXED_VALUE_TYPE.keys}"
        end

        request = Temporalio::Api::OperatorService::V1::AddSearchAttributesRequest.new(
          search_attributes: attributes.map { |name, type| [name, SYMBOL_TO_INDEXED_VALUE_TYPE[type]] }.to_h,
          namespace: namespace
        )
        begin
          operator_client.add_search_attributes(request)
        rescue ::GRPC::AlreadyExists => e
          raise Temporal::SearchAttributeAlreadyExistsFailure, e
        rescue ::GRPC::Internal => e
          # The internal workflow that adds search attributes can fail for a variety of reasons such
          # as recreating a removed attribute with a new type. Wrap these all up into a fall through
          # exception.
          raise Temporal::SearchAttributeFailure, e
        end
      end

      def list_custom_search_attributes(namespace)
        request = Temporalio::Api::OperatorService::V1::ListSearchAttributesRequest.new(
          namespace: namespace
        )
        response = operator_client.list_search_attributes(request)
        response.custom_attributes.map { |name, type| [name, INDEXED_VALUE_TYPE_TO_SYMBOL[type]] }.to_h
      end

      def remove_custom_search_attributes(attribute_names, namespace)
        request = Temporalio::Api::OperatorService::V1::RemoveSearchAttributesRequest.new(
          search_attributes: attribute_names,
          namespace: namespace
        )
        begin
          operator_client.remove_search_attributes(request)
        rescue ::GRPC::NotFound => e
          raise Temporal::NotFoundFailure, e
        end
      end

      def reset_sticky_task_queue
        raise NotImplementedError
      end

      def query_workflow(namespace:, workflow_id:, run_id:, query:, args: nil, query_reject_condition: nil)
        request = Temporalio::Api::WorkflowService::V1::QueryWorkflowRequest.new(
          namespace: namespace,
          execution: Temporalio::Api::Common::V1::WorkflowExecution.new(
            workflow_id: workflow_id,
            run_id: run_id
          ),
          query: Temporalio::Api::Query::V1::WorkflowQuery.new(
            query_type: query,
            query_args: converter.to_query_payloads(args)
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
          raise Temporal::QueryFailed, e.details
        end

        if response.query_rejected
          rejection_status = response.query_rejected.status || 'not specified by server'
          raise Temporal::QueryFailed, "Query rejected: status #{rejection_status}"
        elsif !response.query_result
          raise Temporal::QueryFailed, 'Invalid response from server'
        else
          converter.from_query_payloads(response.query_result)
        end
      end

      def describe_workflow_execution(namespace:, workflow_id:, run_id:)
        request = Temporalio::Api::WorkflowService::V1::DescribeWorkflowExecutionRequest.new(
          namespace: namespace,
          execution: Temporalio::Api::Common::V1::WorkflowExecution.new(
            workflow_id: workflow_id,
            run_id: run_id
          )
        )
        client.describe_workflow_execution(request)
      end

      def describe_task_queue(namespace:, task_queue:)
        request = Temporalio::Api::WorkflowService::V1::DescribeTaskQueueRequest.new(
          namespace: namespace,
          task_queue: Temporalio::Api::TaskQueue::V1::TaskQueue.new(
            name: task_queue
          ),
          task_queue_type: Temporalio::Api::Enums::V1::TaskQueueType::TASK_QUEUE_TYPE_WORKFLOW,
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

      def get_system_info
        client.get_system_info(Temporalio::Api::WorkflowService::V1::GetSystemInfoRequest.new)
      end

      def list_schedules(namespace:, maximum_page_size:, next_page_token:)
        request = Temporalio::Api::WorkflowService::V1::ListSchedulesRequest.new(
          namespace: namespace,
          maximum_page_size: maximum_page_size,
          next_page_token: next_page_token
        )
        resp = client.list_schedules(request)

        Temporal::Schedule::ListSchedulesResponse.new(
          schedules: resp.schedules.map do |schedule|
            Temporal::Schedule::ScheduleListEntry.new(
              schedule_id: schedule.schedule_id,
              memo: converter.from_payload_map(schedule.memo&.fields || {}),
              search_attributes: converter.from_payload_map_without_codec(schedule.search_attributes&.indexed_fields || {}),
              info: schedule.info
            )
          end,
          next_page_token: resp.next_page_token,
        )
      end

      def describe_schedule(namespace:, schedule_id:)
        request = Temporalio::Api::WorkflowService::V1::DescribeScheduleRequest.new(
          namespace: namespace,
          schedule_id: schedule_id
        )

        resp = nil
        begin
          resp = client.describe_schedule(request)
        rescue ::GRPC::NotFound => e
          raise Temporal::NotFoundFailure, e
        end

        Temporal::Schedule::DescribeScheduleResponse.new(
          schedule: resp.schedule,
          info: resp.info,
          memo: converter.from_payload_map(resp.memo&.fields || {}),
          search_attributes: converter.from_payload_map_without_codec(resp.search_attributes&.indexed_fields || {}),
          conflict_token: resp.conflict_token
        )
      end

      def create_schedule(
        namespace:,
        schedule_id:,
        schedule:,
        trigger_immediately: nil,
        backfill: nil,
        memo: nil,
        search_attributes: nil
      )
        initial_patch = nil
        if trigger_immediately || backfill
          initial_patch = Temporalio::Api::Schedule::V1::SchedulePatch.new
          if trigger_immediately
            initial_patch.trigger_immediately = Temporalio::Api::Schedule::V1::TriggerImmediatelyRequest.new(
              overlap_policy: Temporal::Connection::Serializer::ScheduleOverlapPolicy.new(
                schedule.policies&.overlap_policy,
                converter
              ).to_proto
            )
          end

          if backfill
            initial_patch.backfill_request += [Temporal::Connection::Serializer::Backfill.new(backfill, converter).to_proto]
          end
        end

        request = Temporalio::Api::WorkflowService::V1::CreateScheduleRequest.new(
          namespace: namespace,
          schedule_id: schedule_id,
          schedule: Temporal::Connection::Serializer::Schedule.new(schedule, converter).to_proto,
          identity: identity,
          request_id: SecureRandom.uuid,
          memo: Temporalio::Api::Common::V1::Memo.new(
            fields: converter.to_payload_map(memo || {})
          ),
          search_attributes: Temporalio::Api::Common::V1::SearchAttributes.new(
            indexed_fields: converter.to_payload_map_without_codec(search_attributes || {})
          )
        )
        client.create_schedule(request)
      end

      def delete_schedule(namespace:, schedule_id:)
        request = Temporalio::Api::WorkflowService::V1::DeleteScheduleRequest.new(
          namespace: namespace,
          schedule_id: schedule_id,
          identity: identity
        )

        begin
          client.delete_schedule(request)
        rescue ::GRPC::NotFound => e
          raise Temporal::NotFoundFailure, e
        end
      end

      def update_schedule(namespace:, schedule_id:, schedule:, conflict_token: nil)
        request = Temporalio::Api::WorkflowService::V1::UpdateScheduleRequest.new(
          namespace: namespace,
          schedule_id: schedule_id,
          schedule: Temporal::Connection::Serializer::Schedule.new(schedule, converter).to_proto,
          conflict_token: conflict_token,
          identity: identity,
          request_id: SecureRandom.uuid
        )

        begin
          client.update_schedule(request)
        rescue ::GRPC::NotFound => e
          raise Temporal::NotFoundFailure, e
        end
      end

      def trigger_schedule(namespace:, schedule_id:, overlap_policy: nil)
        request = Temporalio::Api::WorkflowService::V1::PatchScheduleRequest.new(
          namespace: namespace,
          schedule_id: schedule_id,
          patch: Temporalio::Api::Schedule::V1::SchedulePatch.new(
            trigger_immediately: Temporalio::Api::Schedule::V1::TriggerImmediatelyRequest.new(
              overlap_policy: Temporal::Connection::Serializer::ScheduleOverlapPolicy.new(
                overlap_policy,
                converter
              ).to_proto
            ),
          ),
          identity: identity,
          request_id: SecureRandom.uuid
        )

        begin
          client.patch_schedule(request)
        rescue ::GRPC::NotFound => e
          raise Temporal::NotFoundFailure, e
        end
      end

      def pause_schedule(namespace:, schedule_id:, should_pause:, note: nil)
        patch = Temporalio::Api::Schedule::V1::SchedulePatch.new
        if should_pause
          patch.pause = note || 'Paused by temporal-ruby'
        else
          patch.unpause = note || 'Unpaused by temporal-ruby'
        end

        request = Temporalio::Api::WorkflowService::V1::PatchScheduleRequest.new(
          namespace: namespace,
          schedule_id: schedule_id,
          patch: patch,
          identity: identity,
          request_id: SecureRandom.uuid
        )

        begin
          client.patch_schedule(request)
        rescue ::GRPC::NotFound => e
          raise Temporal::NotFoundFailure, e
        end
      end

      private

      attr_reader :url, :identity, :credentials, :converter, :options, :poll_mutex, :poll_request

      def client
        return @client if @client

        channel_args = {}

        if options[:keepalive_time_ms]
          channel_args["grpc.keepalive_time_ms"] = options[:keepalive_time_ms]
        end

        if options[:retry_connection] || options[:retry_policy]
          channel_args["grpc.enable_retries"] = 1

          retry_policy = options[:retry_policy] || {
            retryableStatusCodes: ["UNAVAILABLE"],
            maxAttempts: 3,
            initialBackoff: "0.1s",
            backoffMultiplier: 2.0,
            maxBackoff: "0.3s"
          }

          channel_args["grpc.service_config"] = ::JSON.generate(
            methodConfig: [
              {
                name: [
                  {
                    service: "temporal.api.workflowservice.v1.WorkflowService",
                  }
                ],
                retryPolicy: retry_policy
              }
            ]
          )
        end

        @client = Temporalio::Api::WorkflowService::V1::WorkflowService::Stub.new(
          url,
          credentials,
          timeout: CONNECTION_TIMEOUT_SECONDS,
          interceptors: [ClientNameVersionInterceptor.new],
          channel_args: channel_args
        )
      end

      def operator_client
        @operator_client ||= Temporalio::Api::OperatorService::V1::OperatorService::Stub.new(
          url,
          credentials,
          timeout: CONNECTION_TIMEOUT_SECONDS,
          interceptors: [ClientNameVersionInterceptor.new]
        )
      end

      def can_poll?
        @poll
      end

      def serialize_time_filter(from, to)
        Temporalio::Api::Filter::V1::StartTimeFilter.new(
          earliest_time: from&.to_time,
          latest_time: to&.to_time
        )
      end

      def serialize_execution_filter(value)
        return unless value

        Temporalio::Api::Filter::V1::WorkflowExecutionFilter.new(workflow_id: value)
      end

      def serialize_type_filter(value)
        return unless value

        Temporalio::Api::Filter::V1::WorkflowTypeFilter.new(name: value)
      end

      def serialize_status_filter(value)
        return unless value

        sym = Temporal::Workflow::Status::API_STATUS_MAP.invert[value]
        status = Temporalio::Api::Enums::V1::WorkflowExecutionStatus.resolve(sym)

        Temporalio::Api::Filter::V1::StatusFilter.new(status: status)
      end
    end
  end
end
