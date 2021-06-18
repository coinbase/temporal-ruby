class FailingActivity < Temporal::Activity
  retry_policy(max_attempts: 1)

  class MyError < StandardError; end

  def execute(message)
    raise MyError.new(message)
  end
end
