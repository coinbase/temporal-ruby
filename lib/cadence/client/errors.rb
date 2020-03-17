module Cadence
  module Client
    class Error < StandardError; end

    # incorrect arguments passed to the client
    class ArgumentError < Error; end
  end
end
