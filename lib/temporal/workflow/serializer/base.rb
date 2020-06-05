require 'oj'
require 'gen/thrift/shared_types'

module Temporal
  class Workflow
    module Serializer
      class Base
        def initialize(object)
          @object = object
        end

        def to_thrift
          raise NotImplementedError, 'serializer needs to implement #to_thrift'
        end

        private

        attr_reader :object
      end
    end
  end
end
