require 'cadence/concerns/typed'

class RandomNumberActivity < Cadence::Activity
  include Cadence::Concerns::Typed

  input do
    attribute :min, Cadence::Types::Integer.default(0)
    attribute :max, Cadence::Types::Integer
  end

  def execute(input)
    number = rand(input.min..input.max)

    logger.warn(number)

    return number
  end
end
