require 'oj'
require 'gen/temporal/api/common/v1/message_pb'
require 'gen/temporal/api/command/v1/message_pb'

module Temporal
  module Connection
    module Serializer
      class Base
        def initialize(object)
          @object = object
        end

        def to_proto
          raise NotImplementedError, 'serializer needs to implement #to_proto'
        end

        private

        attr_reader :object
      end
    end
  end
end
