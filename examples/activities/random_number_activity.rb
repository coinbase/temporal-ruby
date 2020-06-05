require 'temporal/concerns/typed'

class RandomNumberActivity < Temporal::Activity
  include Temporal::Concerns::Typed

  input do
    attribute :min, Temporal::Types::Integer.default(0)
    attribute :max, Temporal::Types::Integer
  end

  def execute(input)
    number = rand(input.min..input.max)

    logger.warn(number)

    return number
  end
end
