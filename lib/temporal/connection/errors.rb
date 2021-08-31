module Temporal
  module Connection
    class Error < StandardError; end

    # incorrect arguments passed to the connection
    class ArgumentError < Error; end
  end
end
