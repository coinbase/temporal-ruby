require 'temporal/json'

module Temporal
  module Connection
    module Converter
      module Payload
        class ProtoJSON
          ENCODING = 'json/protobuf'.freeze

          def encoding
            ENCODING
          end

          def from_payload(payload)
            # TODO: Add error handling.
            message_type = payload.metadata['messageType']
            descriptor = Google::Protobuf::DescriptorPool.generated_pool.lookup(message_type)
            descriptor.msgclass.decode_json(payload.data)
          end

          def to_payload(data)
            return unless data.is_a?(Google::Protobuf::MessageExts)
            Temporalio::Api::Common::V1::Payload.new(
              metadata: {
                'encoding' => ENCODING,
                'messageType' => data.class.descriptor.name,
              },
              data: data.to_json.b,
            )
          end
        end
      end
    end
  end
end
