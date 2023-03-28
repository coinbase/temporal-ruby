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

  class Error; end
  class InternalError; end
  class ClientError; end
  class TimeoutError; end
  class ActivityException; end

  class ActivityNotRegistered; end

  class ApiError; end

  class NotFoundFailure; end
  class WorkflowExecutionAlreadyStartedFailure; end
  class NamespaceNotActiveFailure; end
  class ClientVersionNotSupportedFailure; end
  class FeatureVersionNotSupportedFailure; end
  class NamespaceAlreadyExistsFailure; end
  class CancellationAlreadyRequestedFailure; end
  class QueryFailed; end
end
