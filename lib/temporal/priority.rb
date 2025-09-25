require 'temporal/errors'

module Temporal
  # Priority configuration for workflow execution
  # Similar to retry_policy, priority is represented as a JSON object with predefined keys
  class Priority < Struct.new(:priority_key, :fairness_key, :fairness_weight, keyword_init: true)

    class InvalidPriority < ClientError; end

    def validate!
      # PriorityKey should be a number if provided
      if priority_key && !priority_key.is_a?(Numeric)
        raise InvalidPriority, 'PriorityKey must be a number'
      end

      # FairnessKey should be a string if provided
      if fairness_key && !fairness_key.is_a?(String)
        raise InvalidPriority, 'FairnessKey must be a string'
      end

      # FairnessWeight should be a number if provided
      if fairness_weight && !fairness_weight.is_a?(Numeric)
        raise InvalidPriority, 'FairnessWeight must be a number'
      end
    end

    def to_hash
      hash = {}
      hash['PriorityKey'] = priority_key if priority_key
      hash['FairnessKey'] = fairness_key if fairness_key
      hash['FairnessWeight'] = fairness_weight if fairness_weight
      hash
    end
  end
end 