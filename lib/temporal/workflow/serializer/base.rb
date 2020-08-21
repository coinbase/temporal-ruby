require 'oj'
require 'gen/temporal/common/v1/message_pb'
require 'gen/temporal/decision/v1/message_pb'

module Temporal
  class Workflow
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
