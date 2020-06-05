# Helper class for serializing/deserializing JSON
require 'oj'

module Temporal
  module JSON
    OJ_OPTIONS = {
      mode: :object
    }.freeze

    def self.serialize(value)
      Oj.dump(value, OJ_OPTIONS)
    end

    def self.deserialize(value)
      Oj.load(value.to_s, OJ_OPTIONS)
    end
  end
end
