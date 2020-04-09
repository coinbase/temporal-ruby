module Cadence
  module Metadata
    class Base
      def activity?
        false
      end

      def decision?
        false
      end

      def workflow?
        false
      end
    end
  end
end
