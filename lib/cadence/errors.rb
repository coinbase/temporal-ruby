module Cadence
  # Superclass for all Cadence errors
  class Error < StandardError; end

  # Superclass for errors specific to Cadence worker itself
  class InternalError < Error; end

  # Superclass for misconfiguration/misuse on the client (user) side
  class ClientError < Error; end

  # Represents any timeout
  class TimeoutError < ClientError; end

  # A superclass for activity exceptions raised explicitly
  # with the itent to propagate to a workflow
  class ActivityException < ClientError; end
end
