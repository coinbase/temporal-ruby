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
      executables[name] = executable
    end

    def find(name)
      executables[name]
    end

    private

    attr_reader :executables
  end
end
