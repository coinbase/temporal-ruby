# Helper class for serializing/deserializing JSON
require 'json'
require 'oj'
require 'set'
require 'temporal/errors'

module Temporal
  module JSON
    OJ_OPTIONS = {
      mode: :object,
      # use ruby's built-in serialization.  If nil, OJ seems to default to ~15 decimal places of precision
      float_precision: 0
    }.freeze

    # ^o allocates instances. ^O is Oj's odd marshaller (Date, DateTime, Rational).
    # ^c / ^C look up Class objects (error serialization v2).
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

    # Oj::Saj sees every hash key assignment. JSON.parse collapses duplicate keys.
    class DuplicateKeyValidator < Oj::Saj
      def initialize
        @hash_key_sets = []
      end

      def hash_start(_key)
        @hash_key_sets << Set.new
      end

      def hash_end(_key)
        @hash_key_sets.pop
      end

      def add_value(_value, key)
        return if key.nil?

        keys = @hash_key_sets.last
        if keys.include?(key)
          raise Temporal::JSONDisallowedClassError,
                "json/plain payload contains duplicate key #{key.inspect}"
        end

        keys << key
      end
    end
    private_constant :DuplicateKeyValidator

    def self.serialize(value)
      Oj.dump(value, OJ_OPTIONS)
    end

    # Fail-closed json/plain: Oj mode :object instantiates any constant named in ^o.
    # Reject duplicate hash keys with Oj::Saj, validate directives on a JSON tree, then
    # Oj.load the original bytes so symbol keys and ^t stay compatible with encode.
    def self.deserialize(value)
      return nil if value.nil?

      raw = value.to_s
      return nil if raw.empty?

      assert_no_duplicate_hash_keys!(raw)
      assert_safe!(::JSON.parse(raw, max_nesting: false))
      Oj.load(raw, OJ_OPTIONS)
    end

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

    def self.assert_no_duplicate_hash_keys!(raw)
      Oj.saj_parse(DuplicateKeyValidator.new, raw)
    end
    private_class_method :assert_no_duplicate_hash_keys!

    def self.assert_safe!(obj)
      case obj
      when Hash
        STRUCT_DIRECTIVE_KEYS.each do |key|
          next unless obj.key?(key)
          next if anonymous_struct_directive?(obj[key])

          name = class_name_from_directive(obj[key])
          unless name && allowed_struct_class?(name)
            raise Temporal::JSONDisallowedClassError,
                  "json/plain payload requested disallowed class #{name.inspect}"
          end
        end

        INSTANCE_DIRECTIVE_KEYS.each do |key|
          next unless obj.key?(key)

          name = class_name_from_directive(obj[key])
          unless name && allowed_instance_class?(name)
            raise Temporal::JSONDisallowedClassError,
                  "json/plain payload requested disallowed class #{name.inspect}"
          end
        end

        ODD_MARSHALLER_KEYS.each do |key|
          next unless obj.key?(key)

          name = class_name_from_directive(obj[key])
          unless name && allowed_odd_class?(name)
            raise Temporal::JSONDisallowedClassError,
                  "json/plain payload requested disallowed class #{name.inspect}"
          end
        end

        CLASS_REFERENCE_DIRECTIVE_KEYS.each do |key|
          next unless obj.key?(key)

          name = class_name_from_directive(obj[key])
          unless name && allowed_class_reference?(name)
            raise Temporal::JSONDisallowedClassError,
                  "json/plain payload requested disallowed class #{name.inspect}"
          end
        end

        obj.each_value { |v| assert_safe!(v) }
      when Array
        obj.each { |v| assert_safe!(v) }
      end
    end
    private_class_method :assert_safe!

    def self.class_name_from_directive(value)
      case value
      when String
        value
      when Array
        value.first if value.first.is_a?(String)
      end
    end
    private_class_method :class_name_from_directive

    def self.registered_class?(name)
      with_allowed_classes { |set| set.include?(name) }
    end
    private_class_method :registered_class?

    def self.allowed_instance_class?(name)
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

    def self.allowed_class_reference?(name)
      return true if registered_class?(name)

      resolve_constant(name).is_a?(Module)
    end
    private_class_method :allowed_class_reference?

    def self.resolve_constant(name)
      parts = name.split('::')
      parts.shift if parts.first.empty?
      return nil if parts.empty?

      parts.reduce(Object) do |mod, part|
        return nil unless mod.is_a?(Module) && mod.const_defined?(part, false)

        mod.const_get(part, false)
      end
    rescue NameError
      nil
    end
    private_class_method :resolve_constant
  end
end
