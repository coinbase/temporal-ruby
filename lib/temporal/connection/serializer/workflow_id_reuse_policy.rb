require 'temporal/connection'

module Temporal
  module Connection
    module Serializer
      class WorkflowIdReusePolicy < Base

        WORKFLOW_ID_REUSE_POLICY = {
          allow_failed: Temporalio::Api::Enums::V1::WorkflowIdReusePolicy::WORKFLOW_ID_REUSE_POLICY_ALLOW_DUPLICATE_FAILED_ONLY,
          allow: Temporalio::Api::Enums::V1::WorkflowIdReusePolicy::WORKFLOW_ID_REUSE_POLICY_ALLOW_DUPLICATE,
          reject: Temporalio::Api::Enums::V1::WorkflowIdReusePolicy::WORKFLOW_ID_REUSE_POLICY_REJECT_DUPLICATE,
          terminate_if_running: Temporalio::Api::Enums::V1::WorkflowIdReusePolicy::WORKFLOW_ID_REUSE_POLICY_TERMINATE_IF_RUNNING
        }.freeze

        def to_proto
          return unless object

          policy = WORKFLOW_ID_REUSE_POLICY[object]
          raise ArgumentError, "Unknown workflow_id_reuse_policy specified: #{object}" unless policy

          policy
        end
      end
    end
  end
end
