require 'temporal/json'

module Temporal
  module Connection
    module Converter
      module Payload
        class ProtoJSON
          ENCODING = 'json/protobuf'.freeze

          # DO NOT UPSTREAM TO COINBASE
          SPECIAL_STRIPE_WORKFLOW_PAYLOAD_TYPES = [
            'com.stripe.workflow_engine.workflows.admin.KickerOfferWorkflowReturn',
            'com.stripe.workflow_engine.workflows.admin.ListWorkflowTypesWorkflowReturn'
          ].freeze

          def encoding
            ENCODING
          end

          def from_payload(payload)
            # TODO: Add error handling.
            message_type = payload.metadata['messageType']
            if SPECIAL_STRIPE_WORKFLOW_PAYLOAD_TYPES.include?(message_type)
              # TODO: (RUN_WOFLO-852)
              #
              # DO NOT UPSTREAM TO COINBASE. THIS IS A STRIPE-SPECIFIC HACK.
              #
              # We get the return values of Horizon workflows that use proto payloads. On the Ruby side the
              # proto contract is not used, but rather a plain old Ruby shim class with the exact same
              # properties.
              #
              # In this setup, the response from the completed workflow contains a messageType metadata
              # field and is encoded as json/protobuf instead of json/plain. However, we have not imported
              # these protos into pay-server, and therefore they will not properly deserialize in the code
              # below. We delegate to the normal JSON serializer here which will deserialize the payload into
              # an untyped hash, which other pay-server code will then convert into a typed object.
              Temporal::JSON.deserialize(payload.data)
            else
              descriptor = Google::Protobuf::DescriptorPool.generated_pool.lookup(message_type)
              descriptor.msgclass.decode_json(payload.data)
            end
          end

          def to_payload(data)
            return unless data.is_a?(Google::Protobuf::MessageExts)
            Temporalio::Api::Common::V1::Payload.new(
              metadata: {
                'encoding' => ENCODING,
                'messageType' => data.class.descriptor.name,
              },
              data: data.to_json,
            )
          end
        end
      end
    end
  end
end
