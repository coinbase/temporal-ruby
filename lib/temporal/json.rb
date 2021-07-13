# Helper class for serializing/deserializing JSON
require 'oj'

module Temporal
  module JSON
    OJ_OPTIONS = {
      mode: :object,
      # use ruby's built-in serialization.  If nil, OJ seems to default to ~15 decimal places of precision
      float_precision: 0
    }.freeze

    def self.serialize(value)
      Oj.dump(value, OJ_OPTIONS)
    end

    def self.deserialize(value)
      Oj.load(value.to_s, OJ_OPTIONS)
    end
  end
end
