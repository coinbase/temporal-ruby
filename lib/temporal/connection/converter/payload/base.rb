module Temporal
  module Connection
    module Converter
      module Payload
        class Base
          def initialize(options = {})
            @options = options
          end

          def encoding
            raise NotImplementedError
          end

          def from_payload(__payload)
            raise NotImplementedError
          end

          def to_payload(_payload)
            raise NotImplementedError
          end

          private

            attr_reader :options
        end
      end
    end
  end
end
