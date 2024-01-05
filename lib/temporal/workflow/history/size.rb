module Temporal
  class Workflow
    class History
      Size = Struct.new(
        :bytes, # integer, total number of bytes used
        :events, # integer, total number of history events used
        :suggest_continue_as_new, # boolean, true if server history length limits are being approached
        keyword_init: true)
    end
  end
end
