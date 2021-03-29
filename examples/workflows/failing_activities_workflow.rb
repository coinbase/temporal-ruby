require 'activities/guess_activity'

class FailingActivitiesWorkflow < Temporal::Workflow
  def execute(count)
    fail_callbacks = {}
    success_callbacks = {}
    futures = (0..count - 1).map do |i|
      f = GuessActivity.execute(i)

      f.done do |result|
        success_callbacks[result] = (success_callbacks[result] || Set.new).add(i)
      end

      f.failed do |exception|
        fail_callbacks[exception.class] = (fail_callbacks[exception.class] || Set.new).add(i)
      end

      f
    end
    workflow.wait_for_all(*futures)

    logger.info("#{futures.count(&:failed?)} activites of #{count} failed")

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
