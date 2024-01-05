module Temporal
  module Schedule
    # ScheduleListEntry is returned by ListSchedules.
    class ScheduleListEntry < Struct.new(:schedule_id, :memo, :search_attributes, :info, keyword_init: true)
      # Override the constructor to make these objects immutable 
      def initialize(*args)
        super(*args)
        self.freeze
      end
    end
  end
end
