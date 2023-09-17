require 'set'

module Temporal
  class Workflow
    module SDKFlags
      HANDLE_SIGNALS_FIRST = 1
      SAVE_FIRST_TASK_SIGNALS = 2

      # Make sure to include all known flags here
      ALL = Set.new([HANDLE_SIGNALS_FIRST, SAVE_FIRST_TASK_SIGNALS])
    end
  end
end
