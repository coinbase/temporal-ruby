# json/plain codec for Temporal payloads.
#
# deserialize:
#   1. PayloadStructureValidator (Oj::Saj): reject duplicate keys and nesting > 512
#   2. assert_safe! on JSON.parse: allowlist ^o / ^O / ^c / ^u class directives
#   3. Oj.load original bytes: keep Time (^t) and symbol keys
require 'json'
require 'oj'
require 'set'
require 'temporal/errors'

module Temporal
  module JSON
    OJ_OPTIONS = {
      mode: :object,
      # use ruby's built-in serialization.  If nil, Oj seems to default to ~15 decimal places of precision
      float_precision: 0
    }.freeze

    MAX_NESTING = 512
    MAX_CLASS_NAME_LENGTH = 256

    # ^o allocates instances. ^O encodes Date, DateTime, and Rational.
    # ^c / ^C look up Class objects. Oj emits ^c when an Exception ivar holds a Class
    # (see spec/unit/lib/temporal/connection/serializer/failure_spec.rb).
    INSTANCE_DIRECTIVE_KEYS = %w[^o].freeze
    ODD_MARSHALLER_KEYS = %w[^O].freeze
    CLASS_REFERENCE_DIRECTIVE_KEYS = %w[^c ^C].freeze
    STRUCT_DIRECTIVE_KEYS = %w[^u].freeze
    ALLOWED_CLASS_SUFFIXES = %w[::Request ::Response].freeze
    ALLOWED_ODD_CLASSES = %w[Date DateTime Rational].freeze
    # Oj dumps these on a raised Exception (~bt_locations). They are not gadget classes.
    ALLOWED_STDLIB_CLASSES = %w[
      Thread::Backtrace
      Thread::Backtrace::Location
    ].freeze

    ALLOWED_CLASSES = Set.new
    ALLOWED_CLASSES_MUTEX = Mutex.new
    private_constant :ALLOWED_CLASSES, :ALLOWED_CLASSES_MUTEX

    DUPLICATE_KEY_ERROR = 'json/plain payload contains duplicate hash key'.freeze
    NESTING_DEPTH_ERROR = 'json/plain payload exceeds maximum nesting depth'.freeze

    # Walks raw bytes before JSON.parse / Oj.load. JSON.parse keeps the last duplicate
    # key; Oj binds ^o on the first. A discarded object or array value can still allocate
    # a class, so every hash key is recorded on scalar, object, and array entry.
    class PayloadStructureValidator < Oj::Saj
      def initialize
        @hash_key_sets = []
        @depth = 0
      end

      def hash_start(key)
        note(key)
        bump_depth!
        @hash_key_sets << Set.new
      end

      def hash_end(_key)
        @hash_key_sets.pop
        @depth -= 1
      end

      def array_start(key)
        note(key)
        bump_depth!
      end

      def array_end(_key)
        @depth -= 1
      end

      def add_value(_value, key)
        note(key)
      end

      private

      def bump_depth!
        @depth += 1
        return if @depth <= Temporal::JSON::MAX_NESTING

        raise Temporal::JSONDisallowedClassError, Temporal::JSON::NESTING_DEPTH_ERROR
      end

      # Saj calls add_value for scalars and hash_start / array_start for containers.
      # Skipping container entry is how duplicate ^u and duplicate "scope" slipped through.
      def note(key)
        return if key.nil?

        keys = @hash_key_sets.last
        return if keys.nil?

        if keys.include?(key)
          raise Temporal::JSONDisallowedClassError, Temporal::JSON::DUPLICATE_KEY_ERROR
        end

        keys << key
      end
    end
    private_constant :PayloadStructureValidator

    def self.serialize(value)
      Oj.dump(value, OJ_OPTIONS)
    end

    # Order matters: Saj first (duplicate keys / depth), then JSON.parse (allowlist on a
    # collapsed tree), then Oj.load of the original bytes so ^t and symbol keys survive.
    def self.deserialize(value)
      return nil if value.nil?

      raw = value.to_s
      return nil if raw.empty?

      assert_payload_structure!(raw)
      assert_safe!(::JSON.parse(raw, max_nesting: MAX_NESTING))
      Oj.load(raw, OJ_OPTIONS)
    end

    # Register an extra class name for json/plain object reconstitution. Use this for
    # application types that are not ::Request / ::Response, Temporal::, or Exception.
    def self.allow_class(name)
      with_allowed_classes { |set| set.add(name.to_s) }
      name.to_s
    end

    def self.allowed_class_names
      with_allowed_classes(&:dup)
    end

    def self.with_allowed_classes
      ALLOWED_CLASSES_MUTEX.synchronize { yield ALLOWED_CLASSES }
    end
    private_class_method :with_allowed_classes

    def self.assert_payload_structure!(raw)
      Oj.saj_parse(PayloadStructureValidator.new, raw)
    end
    private_class_method :assert_payload_structure!

    def self.assert_safe!(obj)
      stack = [obj]
      until stack.empty?
        current = stack.pop
        case current
        when Hash
          validate_hash_directives!(current)
          current.each_value { |v| stack << v unless v.nil? }
        when Array
          current.each { |v| stack << v unless v.nil? }
        end
      end
    end
    private_class_method :assert_safe!

    def self.validate_hash_directives!(obj)
      STRUCT_DIRECTIVE_KEYS.each do |key|
        next unless obj.key?(key)
        next if anonymous_struct_directive?(obj[key])

        name = class_name_from_directive(obj[key])
        unless name && allowed_struct_class?(name)
          raise Temporal::JSONDisallowedClassError,
                "json/plain payload requested disallowed class #{safe_class_label(name)}"
        end
      end

      INSTANCE_DIRECTIVE_KEYS.each do |key|
        next unless obj.key?(key)

        name = class_name_from_directive(obj[key])
        unless name && allowed_instance_class?(name)
          raise Temporal::JSONDisallowedClassError,
                "json/plain payload requested disallowed class #{safe_class_label(name)}"
        end
      end

      ODD_MARSHALLER_KEYS.each do |key|
        next unless obj.key?(key)

        name = class_name_from_directive(obj[key])
        unless name && allowed_odd_class?(name)
          raise Temporal::JSONDisallowedClassError,
                "json/plain payload requested disallowed class #{safe_class_label(name)}"
        end
      end

      CLASS_REFERENCE_DIRECTIVE_KEYS.each do |key|
        next unless obj.key?(key)

        name = class_name_from_directive(obj[key])
        unless name && allowed_class_reference?(name)
          raise Temporal::JSONDisallowedClassError,
                "json/plain payload requested disallowed class #{safe_class_label(name)}"
        end
      end
    end
    private_class_method :validate_hash_directives!

    def self.class_name_from_directive(value)
      case value
      when String
        value
      when Array
        value.first if value.first.is_a?(String)
      end
    end
    private_class_method :class_name_from_directive

    def self.safe_class_label(name)
      return '?' unless valid_constant_name?(name)

      name
    end
    private_class_method :safe_class_label

    def self.valid_constant_name?(name)
      return false unless name.is_a?(String)
      return false if name.empty? || name.length > MAX_CLASS_NAME_LENGTH

      name.split('::').all? { |part| part.match?(/\A[A-Z]\w*\z/) }
    end
    private_class_method :valid_constant_name?

    def self.registered_class?(name)
      with_allowed_classes { |set| set.include?(name) }
    end
    private_class_method :registered_class?

    def self.allowed_instance_class?(name)
      return false unless valid_constant_name?(name)
      return true if registered_class?(name)
      return true if library_class?(name)
      return true if ALLOWED_STDLIB_CLASSES.include?(name) && resolve_constant(name)
      return true if ALLOWED_CLASS_SUFFIXES.any? { |suffix| name.end_with?(suffix) } && resolve_constant(name)

      klass = resolve_constant(name)
      klass.is_a?(Class) && klass <= Exception
    end
    private_class_method :allowed_instance_class?

    def self.allowed_odd_class?(name)
      ALLOWED_ODD_CLASSES.include?(name) && resolve_constant(name)
    end
    private_class_method :allowed_odd_class?

    def self.allowed_struct_class?(name)
      return false unless valid_constant_name?(name)

      registered_class?(name) || library_class?(name)
    end
    private_class_method :allowed_struct_class?

    def self.library_class?(name)
      name.start_with?('Temporal::') && resolve_constant(name).is_a?(Class)
    end
    private_class_method :library_class?

    # Oj encodes Struct.new(:a, :b).new(...) as ^u with member names, not a class.
    def self.anonymous_struct_directive?(value)
      value.is_a?(Array) && value.first.is_a?(Array) && value.first.all? { |member| member.is_a?(String) }
    end
    private_class_method :anonymous_struct_directive?

    # ^c reconstitutes a Class object, not an instance. Tightening this to Temporal:: /
    # Exception / allow_class would break error v2 when an ivar holds an app class.
    def self.allowed_class_reference?(name)
      return false unless valid_constant_name?(name)
      return true if registered_class?(name)

      resolve_constant(name).is_a?(Module)
    end
    private_class_method :allowed_class_reference?

    # Only resolve constants that are already loaded. const_get would trigger autoload.
    def self.resolve_constant(name)
      return nil unless valid_constant_name?(name)

      name.split('::').reduce(Object) do |mod, part|
        return nil unless mod.is_a?(Module)
        return nil if mod.autoload?(part)
        return nil unless mod.const_defined?(part, false)

        mod.const_get(part, false)
      end
    rescue NameError
      nil
    end
    private_class_method :resolve_constant
  end
end
