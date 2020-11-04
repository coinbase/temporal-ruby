module Temporal
  class Activity; end
  class ActivityException; end
  module Client
    class Error; end
    class ArgumentError; end
  end
  module Metadata
    class Activity; end
    class Base; end
    class Workflow; end
    class WorkflowTask; end
  end
  module Saga
    module Concern; end
  end
  module Testing
    class LocalActivityContext; end
  end
  class Workflow
    class ExecutionInfo; end
  end
  class Worker; end
end
module TemporalThrift
  class BadRequestError; end
  class InternalServiceError; end
  class DomainAlreadyExistsError; end
  class WorkflowExecutionAlreadyStartedError; end
  class EntityNotExistsError; end
  class ServiceBusyError; end
  class CancellationAlreadyRequestedError; end
  class QueryFailedError; end
  class DomainNotActiveError; end
  class LimitExceededError; end
  class AccessDeniedError; end
  class RetryTaskError; end
  class ClientVersionNotSupportedError; end
end
