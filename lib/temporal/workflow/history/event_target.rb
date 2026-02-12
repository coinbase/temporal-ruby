require 'temporal/errors'

module Temporal
  class Workflow
    class History
      class EventTarget
        class UnexpectedEventType < InternalError; end
        class UnexpectedCommandType < InternalError; end

        ACTIVITY_TYPE                         = :activity
        CANCEL_ACTIVITY_REQUEST_TYPE          = :cancel_activity_request
        TIMER_TYPE                            = :timer
        CANCEL_TIMER_REQUEST_TYPE             = :cancel_timer_request
        CHILD_WORKFLOW_TYPE                   = :child_workflow
        MARKER_TYPE                           = :marker
        EXTERNAL_WORKFLOW_TYPE                = :external_workflow
        CANCEL_EXTERNAL_WORKFLOW_REQUEST_TYPE = :cancel_external_workflow_request
        WORKFLOW_TYPE                         = :workflow
        CANCEL_WORKFLOW_REQUEST_TYPE          = :cancel_workflow_request
        UPSERT_SEARCH_ATTRIBUTES_REQUEST_TYPE = :upsert_search_attributes_request

        # NOTE: The order is important, first prefix match wins (will be a longer match)
        EVENT_TARGET_TYPES = {
          'ACTIVITY_TASK_CANCEL_REQUESTED'             => CANCEL_ACTIVITY_REQUEST_TYPE,
          'ACTIVITY_TASK'                              => ACTIVITY_TYPE,
          'REQUEST_CANCEL_ACTIVITY_TASK'               => CANCEL_ACTIVITY_REQUEST_TYPE,
          'TIMER_CANCELED'                             => CANCEL_TIMER_REQUEST_TYPE,
          'TIMER'                                      => TIMER_TYPE,
          'CANCEL_TIMER'                               => CANCEL_TIMER_REQUEST_TYPE,
          'CHILD_WORKFLOW_EXECUTION'                   => CHILD_WORKFLOW_TYPE,
          'START_CHILD_WORKFLOW_EXECUTION'             => CHILD_WORKFLOW_TYPE,
          'MARKER'                                     => MARKER_TYPE,
          'EXTERNAL_WORKFLOW_EXECUTION'                => EXTERNAL_WORKFLOW_TYPE,
          'SIGNAL_EXTERNAL_WORKFLOW_EXECUTION'         => EXTERNAL_WORKFLOW_TYPE,
          'EXTERNAL_WORKFLOW_EXECUTION_CANCEL'         => CANCEL_EXTERNAL_WORKFLOW_REQUEST_TYPE,
          'REQUEST_CANCEL_EXTERNAL_WORKFLOW_EXECUTION' => CANCEL_EXTERNAL_WORKFLOW_REQUEST_TYPE,
          'UPSERT_WORKFLOW_SEARCH_ATTRIBUTES'          => UPSERT_SEARCH_ATTRIBUTES_REQUEST_TYPE,
          'WORKFLOW_EXECUTION_CANCEL'                  => CANCEL_WORKFLOW_REQUEST_TYPE,
          'WORKFLOW_EXECUTION'                         => WORKFLOW_TYPE,
        }.freeze

        WORKFLOW_TARGET_TYPES = {
          'Temporal::Workflow::Command::ScheduleActivity'            => ACTIVITY_TYPE,
          'Temporal::Workflow::Command::RequestActivityCancellation' => CANCEL_ACTIVITY_REQUEST_TYPE,
          'Temporal::Workflow::Command::RecordMarker'                => MARKER_TYPE,
          'Temporal::Workflow::Command::StartTimer'                  => TIMER_TYPE,
          'Temporal::Workflow::Command::CancelTimer'                 => CANCEL_TIMER_REQUEST_TYPE,
          'Temporal::Workflow::Command::CompleteWorkflow'            => WORKFLOW_TYPE,
          'Temporal::Workflow::Command::FailWorkflow'                => WORKFLOW_TYPE,
          'Temporal::Workflow::Command::StartChildWorkflow'          => CHILD_WORKFLOW_TYPE,
          'Temporal::Workflow::Command::SignalExternalWorkflow'      => EXTERNAL_WORKFLOW_TYPE,
          'Temporal::Workflow::Command::CancelExternalWorkflow'      => CANCEL_EXTERNAL_WORKFLOW_REQUEST_TYPE,
          'Temporal::Workflow::Command::UpsertSearchAttributes'      => UPSERT_SEARCH_ATTRIBUTES_REQUEST_TYPE,
          'Temporal::Workflow::Command::ContinueAsNew'               => WORKFLOW_TYPE,
        }.freeze

        COMMAND_ATTRIBUTE_LISTS = {
          'Temporal::Workflow::Command::ScheduleActivity'            => [:activity_id, :activity_type, :input],
        }
        attr_reader :id, :type, :attributes

        def self.workflow
          @workflow ||= new(1, WORKFLOW_TYPE)
        end

        def self.from_event(event)
          _, target_type = EVENT_TARGET_TYPES.find { |type, _| event.type.start_with?(type) }

          unless target_type
            raise UnexpectedEventType, "Unexpected event #{event.type}"
          end

          new(event.originating_event_id, target_type, attributes: event.target_attributes)
        end

        def self.from_command(command_id, command)

          command_type = command.class.name
          target_type = WORKFLOW_TARGET_TYPES[command_type]

          unless target_type
            raise UnexpectedCommandType, "Unexpected command type #{command_type}"
          end

          attribute_list = COMMAND_ATTRIBUTE_LISTS.fetch(command_type, [])

          new(command_id, target_type, attributes: command.to_h.slice(*attribute_list))
        end

        def initialize(id, type, attributes: {})
          @id = id
          @type = type
          @attributes = attributes

          freeze
        end

        def ==(other)
          self.class == other.class && id == other.id && type == other.type
        end

        def eql?(other)
          self == other
        end

        def hash
          [id, type].hash
        end

        # Value-aware comparison for attributes that handles plain Ruby objects
        # without custom == (e.g., workflow/activity Request classes).
        #
        # During replay, Temporal deserializes inputs from history and compares
        # them to the current execution. Ruby's default Object#== uses object
        # identity, so two Request objects with identical data compare as unequal,
        # causing false NonDeterministicWorkflowError. This method falls back to
        # instance-variable comparison for objects that don't define their own ==.
        def attributes_equal?(other_attributes)
          return true if attributes == other_attributes
          return false if attributes.nil? || other_attributes.nil?

          normalized_attributes = self.class.normalize_hash_for_compare(attributes)
          normalized_other = self.class.normalize_hash_for_compare(other_attributes)
          return false if normalized_attributes.nil? || normalized_other.nil?
          return false unless normalized_attributes.size == normalized_other.size

          normalized_attributes.all? do |key, value|
            normalized_other.key?(key) && self.class.deep_value_equal?(value, normalized_other[key])
          end
        end

        def self.deep_value_equal?(a, b)
          # Fast path: identical object
          return true if a.equal?(b)

          # Standard types that define meaningful ==
          return a == b if a.is_a?(String) || a.is_a?(Numeric) || a.is_a?(Symbol) ||
                           a.is_a?(TrueClass) || a.is_a?(FalseClass) || a.nil?

          # Arrays: compare element-by-element
          if a.is_a?(Array) && b.is_a?(Array)
            return false if a.length != b.length
            return a.zip(b).all? { |x, y| deep_value_equal?(x, y) }
          end

          # Hashes: compare key-by-key (normalize symbol keys to strings)
          if a.is_a?(Hash) && b.is_a?(Hash)
            normalized_a = normalize_hash_for_compare(a)
            normalized_b = normalize_hash_for_compare(b)
            return false if normalized_a.nil? || normalized_b.nil?
            return false unless normalized_a.size == normalized_b.size

            return normalized_a.all? do |key, value|
              normalized_b.key?(key) && deep_value_equal?(value, normalized_b[key])
            end
          end

          # If the class defines its own == (not inherited from BasicObject/Object)
          eq_owner = a.class.instance_method(:==).owner
          return a == b if eq_owner != ::BasicObject && eq_owner != ::Object

          # Fallback: compare by class + instance variables for plain objects
          return false unless a.class == b.class
          return true if a.instance_variables.empty? && b.instance_variables.empty?

          a.instance_variables.all? do |var|
            deep_value_equal?(a.instance_variable_get(var), b.instance_variable_get(var))
          end
        end

        def to_s
          "#{type}: #{id} (#{attributes})"
        end

        def self.normalize_hash_for_compare(hash)
          normalized = {}
          hash.each do |key, value|
            normalized_key = key.is_a?(Symbol) ? key.to_s : key
            return nil if normalized.key?(normalized_key)

            normalized[normalized_key] = value
          end

          normalized
        end
      end
    end
  end
end
