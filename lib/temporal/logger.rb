require 'logger'

module Temporal
  class Logger < ::Logger
    SEVERITIES = %i[debug info warn error fatal unknown].freeze

    SEVERITIES.each do |severity|
      define_method severity do |message, data = {}|
        super(message.to_s + ' ' + Oj.dump(data, mode: :strict))
      end
    end

    def log(severity, message, data = {})
      add(severity, message.to_s + ' ' + Oj.dump(data, mode: :strict))
    end
  end
end
