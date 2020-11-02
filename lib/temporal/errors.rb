module Temporal
  # Superclass for all Temporal errors
  class Error < StandardError; end

  # Superclass for errors specific to Temporal worker itself
  class InternalError < Error; end

  # Superclass for misconfiguration/misuse on the client (user) side
  class ClientError < Error; end

  # Represents any timeout
  class TimeoutError < ClientError; end

  class ActivityNotRegisteredError < ClientError; end

  # A superclass for activity exceptions raised explicitly
  # with the intent to propagate to a workflow
  class ActivityException < ClientError; end

  class ApiError < Error; end

  class NotFoundFailure < ApiError; end
  class WorkflowExecutionAlreadyStartedFailure < ApiError; end
  class NamespaceNotActiveFailure < ApiError; end
  class ClientVersionNotSupportedFailure < ApiError; end
  class FeatureVersionNotSupportedFailure < ApiError; end
  class NamespaceAlreadyExistsFailure < ApiError; end
  class CancellationAlreadyRequestedFailure < ApiError; end
  class QueryFailedFailure < ApiError; end
end
