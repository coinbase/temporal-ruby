require 'temporal/connection/serializer/base'

module Temporal
  module Connection
    module Serializer
      class ParentClosePolicy < Base
        def to_proto
          return Temporal::Api::Enums::V1::ParentClosePolicy::PARENT_CLOSE_POLICY_UNSPECIFIED unless object
          mapping = {
            abandon: Temporal::Api::Enums::V1::ParentClosePolicy::PARENT_CLOSE_POLICY_ABANDON,
            terminate: Temporal::Api::Enums::V1::ParentClosePolicy::PARENT_CLOSE_POLICY_TERMINATE,
            request_cancel: Temporal::Api::Enums::V1::ParentClosePolicy::PARENT_CLOSE_POLICY_REQUEST_CANCEL,
          }.compact

          mapping[object.policy]
        end
      end
    end
  end
end
