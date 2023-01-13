require 'temporal/errors'
require 'temporal/json'

module Temporal
  class Activity
    # Private exception used to marshal ActivityException from the activity to the workflow.
    # The default serializer can only deal with one initialization arg. This class deals with more
    # --as well as keyword args--as long as the user implements (de)serialization methods on
    # ActivityException.
    class SerializedException < StandardError
      # Returns SerializedException if the ActivityException overrides the serialize method.
      # Otherwise, returns the original exception to maintain backward compatibility.
      def self.from_activity_exception(error)
        unless error.is_a?(Temporal::ActivityException)
          raise ArgumentError, "Cannot serialize #{error.class} as it's not an ActivityException"
        end

        serialized_data = error.serialize_args
        if serialized_data.nil?
          # The user didn't specify a serializer; return the error as-is and hope for the best.
          error
        else
          hash = {
            'error_type' => error.class.name,
            'serialized_data' => serialized_data
          }
          serialized_hash = Temporal::JSON.serialize(hash)

          Temporal::Activity::SerializedException.new(serialized_hash)
        end
      end

      def self.error_type_and_serialized_data(serialized_hash)
        hash = Temporal::JSON.deserialize(serialized_hash)
        [hash['error_type'], hash['serialized_data']]
      end

      def self.to_activity_exception(serialized_hash)
        error_type, serialized_data = error_type_and_serialized_data(serialized_hash)
        exception_class = safe_constantize(error_type)
        raise "Cannot load original error class #{error_type}" if exception_class.nil?

        exception_class.from_serialized_args(serialized_data)
      end

      def self.safe_constantize(const)
        Object.const_get(const) if Object.const_defined?(const)
      rescue NameError
        nil
      end
    end
  end
end
