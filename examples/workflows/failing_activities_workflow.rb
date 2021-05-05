require 'activities/guess_activity'

class FailingActivitiesWorkflow < Temporal::Workflow
  def execute(count)
    fail_callbacks = Hash.new { |_k, _v| Set.new }
    success_callbacks = Hash.new { |_k, _v| Set.new }
    futures = (0..count - 1).map do |i|
      f = GuessActivity.execute(i)

      f.done do |result|
        success_callbacks[result] = success_callbacks[result].add(i)
      end

      f.failed do |exception|
        fail_callbacks[exception.class] = fail_callbacks[exception.class].add(i)
      end

      f
    end
    workflow.wait_for_all(*futures)

    logger.info("Activities failed", { total: count, failed: futures.count(&:failed?) })

    {
      finished: futures.count(&:finished?),
      successes: futures.select(&:ready?).map(&:get),
      terminal_guesses: futures.count { |f| f.get.class == GuessActivity::TerminalGuess },
      wrong_guesses: futures.count { |f| f.get.class == GuessActivity::WrongGuess },
      success_callbacks: success_callbacks,
      fail_callbacks: fail_callbacks
    }
  end
end
