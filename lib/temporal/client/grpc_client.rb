require 'grpc'
require 'securerandom'
require 'temporal/json'
require 'temporal/client/errors'

# Protoc wants all of its generated files on the LOAD_PATH
$LOAD_PATH << File.expand_path('../../gen', __dir__)
require 'gen/temporal/workflowservice/v1/service_services_pb'

module Temporal
  module Client
    class GRPCClient
      WORKFLOW_ID_REUSE_POLICY = {
        allow_failed: Temporal::Api::Enums::V1::WorkflowIdReusePolicy::WORKFLOW_ID_REUSE_POLICY_ALLOW_DUPLICATE_FAILED_ONLY,
        allow: Temporal::Api::Enums::V1::WorkflowIdReusePolicy::WORKFLOW_ID_REUSE_POLICY_ALLOW_DUPLICATE,
        reject: Temporal::Api::Enums::V1::WorkflowIdReusePolicy::WORKFLOW_ID_REUSE_POLICY_REJECT_DUPLICATE
      }.freeze

      def initialize(host, port, identity)
        @url = "#{host}:#{port}"
        @identity = identity
      end

      def register_domain(name:, description: nil, global: false, metrics: false, retention_period: 10)
        request = Temporal::Api::WorkflowService::V1::RegisterNamespaceRequest.new(
          name: name,
          description: description,
          emit_metric: metrics,
          is_global_namespace: global,
          workflow_execution_retention_period_in_days: retention_period
        )
        client.register_namespace(request)
      end

      def describe_domain(name:)
        request = Temporal::Api::WorkflowService::V1::DescribeNamespaceRequest.new(name: name)
        client.describe_namespace(request)
      end

      def list_domains(page_size:)
        request = Temporal::Api::WorkflowService::V1::ListNamespacesRequest.new(page_size: page_size)
        client.list_namespaces(request)
      end

      def update_domain(name:, description:)
        request = Temporal::Api::WorkflowService::V1::UpdateNamespaceRequest.new(
          name: name,
          update_info: Temporal::Api::WorkflowService::V1::UpdateNamespaceInfo.new(
            description: description
          )
        )
        client.update_namespace(request)
      end

      def deprecate_domain(name:)
        request = Temporal::Api::WorkflowService::V1::DeprecateNamespaceRequest.new(name: name)
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
        request = Temporal::Api::WorkflowService::V1::StartWorkflowExecutionRequest.new(
          identity: identity,
          namespace: domain,
          workflow_type: Temporal::Api::Common::V1::WorkflowType.new(
            name: workflow_name
          ),
          workflow_id: workflow_id,
          task_list: Temporal::Api::TaskList::V1::TaskList.new(
            name: task_list
          ),
          input: Temporal::Api::Common::V1::Payloads.new(
            payloads: [Temporal::Api::Common::V1::Payload.new(data: JSON.serialize(input))]
          ),
          workflow_execution_timeout_seconds: execution_timeout,
          workflow_run_timeout_seconds: execution_timeout,
          workflow_task_timeout_seconds: task_timeout,
          request_id: SecureRandom.uuid,
          header: Temporal::Api::Common::V1::Header.new(
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
        request = Temporal::Api::WorkflowService::V1::GetWorkflowExecutionHistoryRequest.new(
          namespace: domain,
          execution: Temporal::Api::Temporal::Api::Common::V1::WorkflowExecution.new(
            workflow_id: workflow_id,
            run_id: run_id
          )
        )

        client.get_workflow_execution_history(request)
      end

      def poll_for_decision_task(domain:, task_list:)
        request = Temporal::Api::WorkflowService::V1::PollForDecisionTaskRequest.new(
          identity: identity,
          namespace: domain,
          task_list: Temporal::Api::TaskList::V1::TaskList.new(
            name: task_list
          )
        )
        client.poll_for_decision_task(request)
      end

      def respond_decision_task_completed(task_token:, decisions:)
        request = Temporal::Api::WorkflowService::V1::RespondDecisionTaskCompletedRequest.new(
          identity: identity,
          task_token: task_token,
          decisions: Array(decisions)
        )
        client.respond_decision_task_completed(request)
      end

      def respond_decision_task_failed(task_token:, cause:, details: nil)
        request = Temporal::Api::WorkflowService::V1::RespondDecisionTaskFailedRequest.new(
          identity: identity,
          task_token: task_token,
          cause: cause,
          details: JSON.serialize(details)
        )
        client.respond_decision_task_failed(request)
      end

      def poll_for_activity_task(domain:, task_list:)
        request = Temporal::Api::WorkflowService::V1::PollForActivityTaskRequest.new(
          identity: identity,
          namespace: domain,
          task_list: Temporal::Api::TaskList::V1::TaskList.new(
            name: task_list
          )
        )
        client.poll_for_activity_task(request)
      end

      def record_activity_task_heartbeat(task_token:, details: nil)
        request = Temporal::Api::WorkflowService::V1::RecordActivityTaskHeartbeatRequest.new(
          task_token: task_token,
          details: JSON.serialize(details),
          identity: identity
        )
        client.record_activity_task_heartbeat(request)
      end

      def record_activity_task_heartbeat_by_id
        raise NotImplementedError
      end

      def respond_activity_task_completed(task_token:, result:)
        request = Temporal::Api::WorkflowService::V1::RespondActivityTaskCompletedRequest.new(
          identity: identity,
          task_token: task_token,
          result: Temporal::Api::Common::V1::Payloads.new(
            payloads: [
              Temporal::Api::Common::V1::Payload.new(data: JSON.serialize(result))
            ]
          ),
        )
        client.respond_activity_task_completed(request)
      end

      def respond_activity_task_completed_by_id(domain:, activity_id:, workflow_id:, run_id:, result:)
        request = Temporal::Api::WorkflowService::V1::RespondActivityTaskCompletedByIdRequest.new(
          identity: identity,
          namespace: domain,
          workflow_id: workflow_id,
          run_id: run_id,
          activity_id: activity_id,
          result: JSON.serialize(result)
        )
        client.respond_activity_task_completed_by_id(request)
      end

      def respond_activity_task_failed(task_token:, reason:, details: nil)
        request = Temporal::Api::WorkflowService::V1::RespondActivityTaskFailedRequest.new(
          identity: identity,
          task_token: task_token,
          reason: reason,
          details: JSON.serialize(details)
        )
        client.respond_activity_task_failed(request)
      end

      def respond_activity_task_failed_by_id(domain:, activity_id:, workflow_id:, run_id:, reason:, details: nil)
        request = Temporal::Api::WorkflowService::V1::RespondActivityTaskFailedByIdRequest.new(
          identity: identity,
          namespace: domain,
          workflow_id: workflow_id,
          run_id: run_id,
          activity_id: activity_id,
          reason: reason,
          details: JSON.serialize(details)
        )
        client.respond_activity_task_failed_by_id(request)
      end

      def respond_activity_task_canceled(task_token:, details: nil)
        request = Temporal::Api::WorkflowService::V1::RespondActivityTaskCanceledRequest.new(
          task_token: task_token,
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
        request = Temporal::Api::WorkflowService::V1::SignalWorkflowExecutionRequest.new(
          namespace: domain,
          workflow_execution: Temporal::Api::Common::V1::WorkflowExecution.new(
            workflow_id: workflow_id,
            run_id: run_id
          ),
          signal_name: signal,
          input: JSON.serialize(input),
          identity: identity
        )
        client.signal_workflow_execution(request)
      end

      def signal_with_start_workflow_execution
        raise NotImplementedError
      end

      def reset_workflow_execution(domain:, workflow_id:, run_id:, reason:, decision_task_event_id:)
        request = Temporal::Api::WorkflowService::V1::ResetWorkflowExecutionRequest.new(
          namespace: domain,
          workflow_execution: Temporal::Api::Common::V1::WorkflowExecution.new(
            workflow_id: workflow_id,
            run_id: run_id
          ),
          reason: reason,
          decision_finish_event_id: decision_task_event_id
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
        request = Temporal::Api::WorkflowService::V1::DescribeWorkflowExecutionRequest.new(
          namespace: domain,
          execution: Temporal::Api::Common::V1::WorkflowExecution.new(
            workflow_id: workflow_id,
            run_id: run_id
          )
        )
        client.describe_workflow_execution(request)
      end

      def describe_task_list(domain:, task_list:)
        request = Temporal::Api::WorkflowService::V1::DescribeTaskListRequest.new(
          namespace: domain,
          task_list: Temporal::Api::TaskList::V1::TaskList.new(
            name: task_list
          ),
          task_list_type: Temporal::Api::Enums::V1::TaskListType::Decision,
          include_task_list_status: true
        )
        client.describe_task_list(request)
      end

      private

      attr_reader :url, :identity

      def client
        @client ||= Temporal::Api::WorkflowService::V1::WorkflowService::Stub.new(
          url,
          :this_channel_is_insecure,
          timeout: 5
        )
      end
    end
  end
end
