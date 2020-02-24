require 'dry-struct'
require 'cadence/types'

module Cadence
  module Concerns
    module Typed
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        attr_reader :input_class

        def execute_in_context(context, input)
          input = input_class[*input] if input_class

          super(context, input)
        end

        def input(klass = nil, &block)
          if klass
            unless klass.is_a?(Dry::Types::Type)
              raise 'Unsupported input class. Use one of the provided Cadence::Types'
            end
            @input_class = klass
          else
            @input_class = generate_struct
            @input_class.instance_eval(&block)
          end
        end

        private

        def generate_struct
          Class.new(Dry::Struct::Value) { transform_keys(&:to_sym) }
        end
      end
    end
  end
end
