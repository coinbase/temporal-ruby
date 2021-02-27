require 'activities/guess_activity'

class FailingActivitiesWorkflow < Temporal::Workflow
  def execute(count)
    futures = (0..count - 1).map { |i| GuessActivity.execute(i) }
    workflow.wait_for_all(*futures)

    logger.info("#{futures.count(&:failed?)} activites of #{count} failed")

    {
      finished: futures.count(&:finished?),
      successes: futures.select(&:ready?).map(&:get),
      terminal_guesses: futures.count { |f| f.get.class == GuessActivity::TerminalGuess },
      wrong_guesses: futures.count { |f| f.get.class == GuessActivity::WrongGuess }
    }
  end
end
