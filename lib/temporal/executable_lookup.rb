require 'temporal/errors'

# This class is responsible for matching an executable (activity or workflow) name
# to a class implementing it.
#
# TODO: This class should be responsible for handling executable versions
#       when these are implemented
#
module Temporal
  class ExecutableLookup

    class SecondDynamicExecutableError < StandardError
      attr_reader :previous_executable_name

      def initialize(previous_executable_name)
        @previous_executable_name = previous_executable_name
      end
    end

    ExecutableNotFoundError = Class.new(StandardError)

    def initialize
      @executables = {}
    end

    # Register an executable to call as a fallback when one of that name isn't registered.
    def add_dynamic(name, executable)
      if @fallback_executable_name
        raise SecondDynamicExecutableError, @fallback_executable_name
      end

      @fallback_executable_class_name = executable.is_a?(String) ? executable : executable.name
      @fallback_executable_name = name
    end

    def add(name, executable)
      executables[name] = executable.is_a?(String) ? executable : executable.name
    end

    def find(name)
      if executables[name]
        resolve_executable(executables[name])
      elsif @fallback_executable_class_name
        resolve_executable(@fallback_executable_class_name)
      else
        nil
      end
    end

    private

    def resolve_executable(class_name)
      Object.const_get(class_name)
    rescue NameError
      raise Temporal::ExecutableLookup::ExecutableNotFoundError, "Executable #{class_name} not found"
    end

    attr_reader :executables, :fallback_executable_name, :fallback_executable_class_name
  end
end
