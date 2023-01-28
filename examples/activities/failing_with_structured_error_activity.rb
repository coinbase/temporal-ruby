require 'temporal/json'

# Illustrates raising an error with a non-standard initializer that
# is handleable by the Workflow.
class FailingWithStructuredErrorActivity < Temporal::Activity
  retry_policy(max_attempts: 1)

  class MyError < Temporal::ActivityException
    attr_reader :foo, :bar

    def initialize(foo, bar)
      @foo = foo
      @bar = bar
    end
  end

  def execute(foo, bar)
    # Pass activity args into the error for better testing
    raise MyError.new(foo, bar)
  end
end
