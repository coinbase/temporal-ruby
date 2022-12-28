require 'temporal/errors'

# This class is responsible for matching an executable (activity or workflow) name
# to a class implementing it.
#
# TODO: This class should be responsible for handling executable versions
#       when these are implemented
#
module Temporal
  class ExecutableLookup
    def initialize
      @executables = {}
    end

    # Register an executable to call as a fallback when one of that name isn't registered.
    def add_dynamic(name, executable)
      if @fallback_executable
        raise Temporal::TypeAlreadyRegisteredError.new(
          "Cannot register #{name} dynamically; #{fallback_executable_name} is already registered " \
          "dynamically, and there can be only one per task queue."
        )
      end
      @fallback_executable = executable
      @fallback_executable_name = name
    end

    def add(name, executable)
      executables[name] = executable
    end

    def find(name)
      executables[name] || @fallback_executable
    end

    private

    attr_reader :executables, :fallback_executable, :fallback_executable_name
  end
end
