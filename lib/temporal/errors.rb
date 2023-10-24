module Temporal
  # Superclass for all Temporal errors
  class Error < StandardError; end

  # Superclass for errors specific to Temporal worker itself
  class InternalError < Error; end

  # Indicates a non-deterministic workflow execution, might be due to
  # a non-deterministic workflow implementation or the gem's bug
  class NonDeterministicWorkflowError < InternalError; end

  # Indicates a workflow task was encountered that used an unknown SDK flag
  class UnknownSDKFlagError < InternalError; end

  # Superclass for misconfiguration/misuse on the client (user) side
  class ClientError < Error; end

  # Represents any timeout
  class TimeoutError < ClientError; end

  # Represents when a child workflow times out
  class ChildWorkflowTimeoutError < Error; end

  # Represents when a child workflow is terminated
  class ChildWorkflowTerminatedError < Error; end

  # A superclass for activity exceptions raised explicitly
  # with the intent to propagate to a workflow
  # With v2 serialization (set with Temporal.configuration set with use_error_serialization_v2=true) you can
  # throw any exception from an activity and expect that it can be handled by the workflow.
  class ActivityException < ClientError; end

  # Represents cancellation of a non-started activity
  class ActivityCanceled < ActivityException; end

  # Activities may be interrupted by three causes: cancellation, shut down, or time out. You can
  # rescue the more specific error classes below if you want to vary behavior in different
  # interruption situations. If you are not sure, don't rescue this error and simply allow it
  # to fail your activity, which will then be retried according to its retry policy.
  class ActivityInterrupted < ActivityException; end

  # Raised by Activity.heartbeat_interrupt if the activity has been canceled directly by its
  # workflow or indirectly by its workflow being terminated.
  class ActivityExecutionCanceled < ActivityInterrupted; end

  # Raised by Activity.heartbeat_interrupt if the worker has started shutting down upon receiving a
  # TERM or INT signal. Once this happens, your activity should finishing processing quickly or
  # raise an error to fail the activity attempt. You can easily do the latter by simply not
  # rescuing this error.
  class ActivityWorkerShuttingDown < ActivityInterrupted; end

  # Raised by Activity.heartbeat_interrupt if the activity has breached its start-to-close
  # or schedule-to-close timeout.
  class ActivityExecutionTimedOut < ActivityInterrupted; end

  class ActivityNotRegistered < ClientError; end
  class WorkflowNotRegistered < ClientError; end
  class SecondDynamicActivityError < ClientError; end
  class SecondDynamicWorkflowError < ClientError; end

  class ApiError < Error; end

  class NotFoundFailure < ApiError; end

  # Superclass for system errors raised when retrieving a workflow result on the
  # client, but the workflow failed remotely.
  class WorkflowError < Error; end

  class WorkflowTimedOut < WorkflowError; end
  class WorkflowTerminated < WorkflowError; end
  class WorkflowCanceled < WorkflowError; end

  # Errors where the workflow run didn't complete but not an error for the whole workflow.
  class WorkflowRunError < Error; end

  class WorkflowRunContinuedAsNew < WorkflowRunError
    attr_reader :new_run_id

    def initialize(new_run_id:)
      super
      @new_run_id = new_run_id
    end
  end

  # Once the workflow succeeds, fails, or continues as new, you can't issue any other commands such as
  # scheduling an activity.  This error is thrown if you try, before we report completion back to the server.
  # This could happen due to activity futures that aren't awaited before the workflow closes,
  # calling workflow.continue_as_new, workflow.complete, or workflow.fail in the middle of your workflow code,
  # or an internal framework bug.
  class WorkflowAlreadyCompletingError < InternalError; end

  class WorkflowExecutionAlreadyStartedFailure < ApiError
    attr_reader :run_id

    def initialize(message, run_id = nil)
      super(message)
      @run_id = run_id
    end
  end

  class NamespaceNotActiveFailure < ApiError; end
  class ClientVersionNotSupportedFailure < ApiError; end
  class FeatureVersionNotSupportedFailure < ApiError; end
  class NamespaceAlreadyExistsFailure < ApiError; end
  class CancellationAlreadyRequestedFailure < ApiError; end
  class QueryFailed < ApiError; end

  class SearchAttributeAlreadyExistsFailure < ApiError; end
  class SearchAttributeFailure < ApiError; end
  class InvalidSearchAttributeTypeFailure < ClientError; end
end
