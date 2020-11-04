module Temporal
  module Metadata
    class Base
      def activity?
        false
      end

      def workflow_task?
        false
      end

      def workflow?
        false
      end
    end
  end
end
