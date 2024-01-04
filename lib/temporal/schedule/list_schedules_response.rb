module Temporal
  module Schedule
    class ListSchedulesResponse < Struct.new(:schedules, :next_page_token, keyword_init: true)
      # Override the constructor to make these objects immutable 
      def initialize(*args)
        super(*args)
        self.freeze
      end
    end
  end
end
