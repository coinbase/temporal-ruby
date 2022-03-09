require 'time'
module Temporal
  class Workflow
    class Context
      # Shared between Context and LocalWorkflowContext so we can do the same validations in test and production.
      module Helpers

        def self.process_search_attributes(search_attributes)
          if search_attributes.nil?
            raise ArgumentError, 'search_attributes cannot be nil'
          end
          if !search_attributes.is_a?(Hash)
            raise ArgumentError, "for search_attributes, expecting a Hash, not #{search_attributes.class}"
          end
          if search_attributes.empty?
            raise ArgumentError, "Cannot upsert an empty hash for search_attributes, as this would do nothing."
          end
          search_attributes.transform_values do |attribute|
            if attribute.is_a?(Time)
              # The server expects UTC times in the standard format.
              attribute.utc.iso8601
            else
              attribute
            end
          end
        end
      end
    end
  end
end
