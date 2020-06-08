require 'grpc'
require 'securerandom'
require 'temporal/json'
require 'temporal/client/errors'

$LOAD_PATH << File.expand_path('../../gen/grpc', __dir__)
require 'workflowservice/service_services_pb'

module Temporal
  module Client
    class GRPCClient
      WORKFLOW_ID_REUSE_POLICY = {
        allow_failed: Temporal::Proto::WorkflowIdReusePolicy::AllowDuplicateFailedOnly,
        allow: Temporal::Proto::WorkflowIdReusePolicy::AllowDuplicate,
        reject: Temporal::Proto::WorkflowIdReusePolicy::RejectDuplicate
      }.freeze

      def initialize(host, port, identity)
        @url = "#{host}:#{port}"
        @identity = identity
      end

      def register_namespace(name:, description: nil, global: false, metrics: false, retention_period: 10)
        request = Temporal::Proto::RegisterNamespaceRequest.new(
          name: name,
          description: description,
          emitMetric: metrics,
          isGlobalNamespace: global,
          workflowExecutionRetentionPeriodInDays: retention_period
        )
        client.register_namespace(request)
      end

      def describe_namespace(name:)
        request = Temporal::Proto::DescribeNamespaceRequest.new(name: name)
        client.describe_namespace(request)
      end

      def list_namespaces(page_size:)
        request = Temporal::Proto::ListNamespacesRequest.new(pageSize: page_size)
        client.list_namespaces(request)
      end

      def update_namespace(name:, description:)
        request = Temporal::Proto::UpdateNamespaceRequest.new(
          name: name,
          updateInfo: Temporal::Proto::UpdateNamespaceRequest.new(
            description: description
          )
        )
        client.update_namespace(request)
      end

      def deprecate_namespace(name:)
        request = Temporal::Proto::DeprecateNamespaceRequest.new(name: name)
        client.deprecate_namespace(request)
      end

      def start_workflow_execution(
        domain:,
        workflow_id:,
        workflow_name:,
        task_list:,
        input: nil,
        execution_timeout:,
        task_timeout:,
        workflow_id_reuse_policy: nil,
        headers: nil
      )
        request = Temporal::Proto::StartWorkflowExecutionRequest.new(
          identity: identity,
          namespace: domain,
          workflowType: Temporal::Proto::WorkflowType.new(
            name: workflow_name
          ),
          workflowId: workflow_id,
          taskList: Temporal::Proto::TaskList.new(
            name: task_list
          ),
          input: Temporal::Proto::Payloads.new(
            payloads: [Temporal::Proto::Payload.new(data: JSON.serialize(input))]
          ),
          workflowExecutionTimeoutSeconds: execution_timeout,
          workflowRunTimeoutSeconds: execution_timeout,
          workflowTaskTimeoutSeconds: task_timeout,
          requestId: SecureRandom.uuid,
          header: Temporal::Proto::Header.new(
            fields: headers
          )
        )

        if workflow_id_reuse_policy
          policy = WORKFLOW_ID_REUSE_POLICY[workflow_id_reuse_policy]
          raise Client::ArgumentError, 'Unknown workflow_id_reuse_policy specified' unless policy

          request.workflowIdReusePolicy = policy
        end

        client.start_workflow_execution(request)
      end

      def get_workflow_execution_history(domain:, workflow_id:, run_id:)
        request = Temporal::Proto::GetWorkflowExecutionHistoryRequest.new(
          namespace: domain,
          execution: Temporal::Proto::WorkflowExecution.new(
            workflowId: workflow_id,
            runId: run_id
          )
        )

        client.get_workflow_execution_history(request)
      end

      def poll_for_decision_task(domain:, task_list:)
        request = Temporal::Proto::PollForDecisionTaskRequest.new(
          identity: identity,
          namespace: domain,
          taskList: Temporal::Proto::TaskList.new(
            name: task_list
          )
        )
        client.poll_for_decision_task(request)
      end

      def respond_decision_task_completed(task_token:, decisions:)
        request = Temporal::Proto::RespondDecisionTaskCompletedRequest.new(
          identity: identity,
          taskToken: task_token,
          decisions: Array(decisions)
        )
        client.respond_decision_task_completed(request)
      end

      def respond_decision_task_failed(task_token:, cause:, details: nil)
        request = Temporal::Proto::RespondDecisionTaskFailedRequest.new(
          identity: identity,
          taskToken: task_token,
          cause: cause,
          details: JSON.serialize(details)
        )
        client.respond_decision_task_failed(request)
      end

      def poll_for_activity_task(domain:, task_list:)
        request = Temporal::Proto::PollForActivityTaskRequest.new(
          identity: identity,
          namespace: domain,
          taskList: Temporal::Proto::TaskList.new(
            name: task_list
          )
        )
        client.poll_for_activity_task(request)
      end

      def record_activity_task_heartbeat(task_token:, details: nil)
        request = Temporal::Proto::RecordActivityTaskHeartbeatRequest.new(
          taskToken: task_token,
          details: JSON.serialize(details),
          identity: identity
        )
        client.record_activity_task_heartbeat(request)
      end

      def record_activity_task_heartbeat_by_id
        raise NotImplementedError
      end

      def respond_activity_task_completed(task_token:, result:)
        request = Temporal::Proto::RespondActivityTaskCompletedRequest.new(
          identity: identity,
          taskToken: task_token,
          result: Temporal::Proto::Payloads.new(
            payloads: [
              Temporal::Proto::Payload.new(data: JSON.serialize(result))
            ]
          ),
        )
        client.respond_activity_task_completed(request)
      end

      def respond_activity_task_completed_by_id(domain:, activity_id:, workflow_id:, run_id:, result:)
        request = Temporal::Proto::RespondActivityTaskCompletedByIDRequest.new(
          identity: identity,
          namespace: domain,
          workflowID: workflow_id,
          runID: run_id,
          activityID: activity_id,
          result: JSON.serialize(result)
        )
        client.respond_activity_task_completed_by_id(request)
      end

      def respond_activity_task_failed(task_token:, reason:, details: nil)
        request = Temporal::Proto::RespondActivityTaskFailedRequest.new(
          identity: identity,
          taskToken: task_token,
          reason: reason,
          details: JSON.serialize(details)
        )
        client.respond_activity_task_failed(request)
      end

      def respond_activity_task_failed_by_id(domain:, activity_id:, workflow_id:, run_id:, reason:, details: nil)
        request = Temporal::Proto::RespondActivityTaskFailedByIDRequest.new(
          identity: identity,
          namespace: domain,
          workflowID: workflow_id,
          runID: run_id,
          activityID: activity_id,
          reason: reason,
          details: JSON.serialize(details)
        )
        client.respond_activity_task_failed_by_id(request)
      end

      def respond_activity_task_canceled(task_token:, details: nil)
        request = Temporal::Proto::RespondActivityTaskCanceledRequest.new(
          taskToken: task_token,
          details: JSON.serialize(details),
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

      def signal_workflow_execution(domain:, workflow_id:, run_id:, signal:, input: nil)
        request = Temporal::Proto::SignalWorkflowExecutionRequest.new(
          namespace: domain,
          workflowExecution: Temporal::Proto::WorkflowExecution.new(
            workflowId: workflow_id,
            runId: run_id
          ),
          signalName: signal,
          input: JSON.serialize(input),
          identity: identity
        )
        client.signal_workflow_execution(request)
      end

      def signal_with_start_workflow_execution
        raise NotImplementedError
      end

      def reset_workflow_execution(domain:, workflow_id:, run_id:, reason:, decision_task_event_id:)
        request = Temporal::Proto::ResetWorkflowExecutionRequest.new(
          namespace: domain,
          workflowExecution: Temporal::Proto::WorkflowExecution.new(
            workflowId: workflow_id,
            runId: run_id
          ),
          reason: reason,
          decisionFinishEventId: decision_task_event_id
        )
        client.reset_workflow_execution(request)
      end

      def terminate_workflow_execution
        raise NotImplementedError
      end

      def list_open_workflow_executions
        raise NotImplementedError
      end

      def list_closed_workflow_executions
        raise NotImplementedError
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

      def respond_query_task_completed
        raise NotImplementedError
      end

      def reset_sticky_task_list
        raise NotImplementedError
      end

      def query_workflow
        raise NotImplementedError
      end

      def describe_workflow_execution(domain:, workflow_id:, run_id:)
        request = Temporal::Proto::DescribeWorkflowExecutionRequest.new(
          namespace: domain,
          execution: Temporal::Proto::WorkflowExecution.new(
            workflowId: workflow_id,
            runId: run_id
          )
        )
        client.describe_workflow_execution(request)
      end

      def describe_task_list(domain:, task_list:)
        request = Temporal::Proto::DescribeTaskListRequest.new(
          namespace: domain,
          taskList: Temporal::Proto::TaskList.new(
            name: task_list
          ),
          taskListType: Temporal::Proto::TaskListType::Decision,
          includeTaskListStatus: true
        )
        client.describe_task_list(request)
      end

      private

      attr_reader :url, :identity

      def client
        @client ||= Temporal::Proto::WorkflowService::Stub.new(url, :this_channel_is_insecure, timeout: 5)
      end
    end
  end
end
