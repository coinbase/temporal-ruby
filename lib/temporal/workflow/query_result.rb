module Temporal
  class Workflow
    module QueryResult
      Answer = Struct.new(:result)
      Failure = Struct.new(:error)

      def self.answer(result)
        Answer.new(result)
      end

      def self.failure(error)
        Failure.new(error)
      end
    end
  end
end
