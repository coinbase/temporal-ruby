require 'logger'

module Temporal
  class Logger < ::Logger
    def debug(message, data = {})
      super(message.to_s + ' ' + JSON.serialize(data))
    end

    def info(message, data = {})
      super(message.to_s + ' ' + JSON.serialize(data))
    end

    def warn(message, data = {})
      super(message.to_s + ' ' + JSON.serialize(data))
    end

    def error(message, data = {})
      super(message.to_s + ' ' + JSON.serialize(data))
    end

    def fatal(message, data = {})
      super(message.to_s + ' ' + JSON.serialize(data))
    end
  end
end
