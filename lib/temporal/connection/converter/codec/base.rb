module Temporal
  module Connection
    module Converter
      module Codec
        class Base
          def encodes(payloads)
            return nil if payloads.nil?

            Temporalio::Api::Common::V1::Payloads.new(
              payloads: payloads.payloads.map(&method(:encode))
            )
          end

          def decodes(payloads)
            return nil if payloads.nil?

            Temporalio::Api::Common::V1::Payloads.new(
              payloads: payloads.payloads.map(&method(:decode))
            )
          end

          def encode(payload)
            raise NotImplementedError, 'codec converter needs to implement encode'
          end

          def decode(payload)
            raise NotImplementedError, 'codec converter needs to implement decode'
          end
        end
      end
    end
  end
end
