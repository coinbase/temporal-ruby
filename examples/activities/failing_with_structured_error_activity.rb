require 'temporal/json'

# Illustrates subclassing Temporal::ActivityException to raise an error that
# is handleable by the Workflow.
class FailingWithStructuredErrorActivity < Temporal::Activity
  retry_policy(max_attempts: 1)

  class MyError < Temporal::ActivityException
    attr_reader :foo, :bar

    def initialize(foo, bar)
      @foo = foo
      @bar = bar
    end

    def serialize_args
      # Users can use whatever serialization they would like
      Temporal::JSON.serialize({ 'foo' => @foo, 'bar' => @bar })
    end

    def self.from_serialized_args(payload)
      hash = Temporal::JSON.deserialize(payload)
      MyError.new(hash['foo'], hash['bar'])
    end
  end

  def execute(foo, bar)
    # Pass activity args into the error for better testing
    raise MyError.new(foo, bar)
  end
end
