require 'temporal/connection'

module Temporal
  module Connection
    module Serializer
      class WorkflowIdReusePolicy

        WORKFLOW_ID_REUSE_POLICY = {
          allow_failed: Temporal::Api::Enums::V1::WorkflowIdReusePolicy::WORKFLOW_ID_REUSE_POLICY_ALLOW_DUPLICATE_FAILED_ONLY,
          allow: Temporal::Api::Enums::V1::WorkflowIdReusePolicy::WORKFLOW_ID_REUSE_POLICY_ALLOW_DUPLICATE,
          reject: Temporal::Api::Enums::V1::WorkflowIdReusePolicy::WORKFLOW_ID_REUSE_POLICY_REJECT_DUPLICATE
        }.freeze

        def self.to_proto(reuse_policy_sym)
          return nil if reuse_policy_sym.nil?

          policy = WORKFLOW_ID_REUSE_POLICY[reuse_policy_sym]
          raise ArgumentError, "Unknown workflow_id_reuse_policy specified: #{reuse_policy_sym}" unless policy

          policy
        end
      end
    end
  end
end
