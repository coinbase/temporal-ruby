module Temporal
  module Schedule
    class Schedule
      attr_reader :spec, :action, :policies, :state

      def initialize(spec:, action:, policies: nil, state: nil)
        @spec = spec
        @action = action
        @policies = policies
        @state = state
      end
    end
  end
end
