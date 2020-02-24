class RandomlyFailingActivity < Cadence::Activity
  class WrongGuess < Cadence::ActivityException; end
  class TerminalGuess < Cadence::ActivityException; end

  retry_policy(
    interval: 1,
    backoff: 1,
    max_attempts: 3,
    non_retriable_errors: [TerminalGuess]
  )

  def execute
    guess = rand(6)

    if guess == 0
      raise TerminalGuess, 'You are the unluckiest!'
    elsif guess != 2
      raise WrongGuess, 'Better luck next time'
    end
  end
end
