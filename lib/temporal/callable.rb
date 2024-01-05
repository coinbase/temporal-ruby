# frozen_string_literal: true

module Temporal
  class Callable
    def initialize(method:)
      @method = method
    end

    def call(input)
      if input.is_a?(Array) && input.last.instance_of?(Hash)
        *args, kwargs = input

        @method.call(*args, **kwargs)
      else
        @method.call(*input)
      end
    end
  end
end
