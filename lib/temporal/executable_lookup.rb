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

    def add(name, executable)
      if executable.dynamic?
        if @fallback_executable
          raise Temporal::TypeAlreadyRegisteredError.new(
            "Cannot register #{name} marked as dynamic; #{fallback_executable_name} is already registered as " \
            "dynamic, and there can be only one."
          )
        end
        @fallback_executable = executable
        @fallback_executable_name = name
      else
        executables[name] = executable
      end
    end

    def find(name)
      executables[name] || @fallback_executable
    end

    private

    attr_reader :executables, :fallback_executable, :fallback_executable_name
  end
end
