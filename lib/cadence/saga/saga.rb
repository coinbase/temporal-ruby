module Cadence
  module Saga
    class Saga
      def initialize(context)
        @context = context
        @compensations = []
      end

      def add_compensation(activity, *args)
        compensations << [activity, args]
      end

      def compensate
        compensations.reverse_each do |(activity, args)|
          context.execute_activity!(activity, *args)
        end
      end

      private

      attr_reader :context, :compensations
    end
  end
end
