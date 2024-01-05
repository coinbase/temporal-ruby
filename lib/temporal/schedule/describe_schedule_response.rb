module Temporal
  module Schedule
    class DescribeScheduleResponse < Struct.new(:schedule, :info, :memo, :search_attributes, :conflict_token, keyword_init: true)
      # Override the constructor to make these objects immutable 
      def initialize(*args)
        super(*args)
        self.freeze
      end
    end
  end
end
