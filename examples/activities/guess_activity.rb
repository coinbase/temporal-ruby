class GuessActivity < Temporal::Activity
  class WrongGuess < Temporal::ActivityException; end
  class TerminalGuess < Temporal::ActivityException; end

  retry_policy(
    interval: 1,
    backoff: 1,
    max_attempts: 3,
    non_retriable_errors: [TerminalGuess]
  )

  def execute(guess)
    raise TerminalGuess, 'You are the unluckiest!' if guess.zero?
    raise WrongGuess, 'Better luck next time' if guess != 2

    'two'
  end
end
