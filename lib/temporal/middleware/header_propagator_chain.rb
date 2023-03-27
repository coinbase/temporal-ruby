module Temporal
  module Middleware
    class HeaderPropagatorChain
      def initialize(entries = [])
        @propagators = entries.map(&:init_middleware)
      end

      def inject(headers)
        return headers if propagators.empty?
        h = headers.dup
        for propagator in propagators
          propagator.inject!(h)
        end
        h
      end

      private

      attr_reader :propagators
    end
  end
end