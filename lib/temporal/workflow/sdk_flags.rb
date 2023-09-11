require 'set'

module Temporal
  class Workflow
    module SDKFlags
      HANDLE_SIGNALS_FIRST = 1

      # Make sure to include all known flags here
      ALL = Set.new([HANDLE_SIGNALS_FIRST])
    end
  end
end
