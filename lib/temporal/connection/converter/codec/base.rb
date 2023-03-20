module Temporal
  module Connection
    module Converter
      module Codec
        class Base
          def encodes(payloads)
            return nil if payloads.nil?

            payloads.payloads.map(&method(:encode))
          end

          def decodes(data)
            return nil if data.nil?

            Temporalio::Api::Common::V1::Payloads.new(
              payloads: data.map(&method(:decode))
            )
          end

          def encode
            raise NotImplementedError, 'codec converter needs to implement encode'
          end

          def decode
            raise NotImplementedError, 'codec converter needs to implement decode'
          end
        end
      end
    end
  end
end
