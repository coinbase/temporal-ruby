# Generated by the protocol buffer compiler.  DO NOT EDIT!
# Source: temporal/api/workflowservice/v1/service.proto for package 'Temporalio.Api.WorkflowService.V1'
# Original file comments:
# The MIT License
#
# Copyright (c) 2020 Temporal Technologies Inc.  All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

require 'grpc'
require 'temporal/api/workflowservice/v1/service_pb'

module Temporalio
  module Api
    module WorkflowService
      module V1
        module WorkflowService
          # WorkflowService API defines how Temporal SDKs and other clients interact with the Temporal server
          # to create and interact with workflows and activities.
          #
          # Users are expected to call `StartWorkflowExecution` to create a new workflow execution.
          #
          # To drive workflows, a worker using a Temporal SDK must exist which regularly polls for workflow
          # and activity tasks from the service. For each workflow task, the sdk must process the
          # (incremental or complete) event history and respond back with any newly generated commands.
          #
          # For each activity task, the worker is expected to execute the user's code which implements that
          # activity, responding with completion or failure.
          class Service

            include ::GRPC::GenericService

            self.marshal_class_method = :encode
            self.unmarshal_class_method = :decode
            self.service_name = 'temporal.api.workflowservice.v1.WorkflowService'

            # RegisterNamespace creates a new namespace which can be used as a container for all resources.
            #
            # A Namespace is a top level entity within Temporal, and is used as a container for resources
            # like workflow executions, task queues, etc. A Namespace acts as a sandbox and provides
            # isolation for all resources within the namespace. All resources belongs to exactly one
            # namespace.
            rpc :RegisterNamespace, ::Temporalio::Api::WorkflowService::V1::RegisterNamespaceRequest, ::Temporalio::Api::WorkflowService::V1::RegisterNamespaceResponse
            # DescribeNamespace returns the information and configuration for a registered namespace.
            rpc :DescribeNamespace, ::Temporalio::Api::WorkflowService::V1::DescribeNamespaceRequest, ::Temporalio::Api::WorkflowService::V1::DescribeNamespaceResponse
            # ListNamespaces returns the information and configuration for all namespaces.
            rpc :ListNamespaces, ::Temporalio::Api::WorkflowService::V1::ListNamespacesRequest, ::Temporalio::Api::WorkflowService::V1::ListNamespacesResponse
            # UpdateNamespace is used to update the information and configuration of a registered
            # namespace.
            #
            # (-- api-linter: core::0134::method-signature=disabled
            #     aip.dev/not-precedent: UpdateNamespace RPC doesn't follow Google API format. --)
            # (-- api-linter: core::0134::response-message-name=disabled
            #     aip.dev/not-precedent: UpdateNamespace RPC doesn't follow Google API format. --)
            rpc :UpdateNamespace, ::Temporalio::Api::WorkflowService::V1::UpdateNamespaceRequest, ::Temporalio::Api::WorkflowService::V1::UpdateNamespaceResponse
            # DeprecateNamespace is used to update the state of a registered namespace to DEPRECATED.
            #
            # Once the namespace is deprecated it cannot be used to start new workflow executions. Existing
            # workflow executions will continue to run on deprecated namespaces.
            # Deprecated.
            rpc :DeprecateNamespace, ::Temporalio::Api::WorkflowService::V1::DeprecateNamespaceRequest, ::Temporalio::Api::WorkflowService::V1::DeprecateNamespaceResponse
            # StartWorkflowExecution starts a new workflow execution.
            #
            # It will create the execution with a `WORKFLOW_EXECUTION_STARTED` event in its history and
            # also schedule the first workflow task. Returns `WorkflowExecutionAlreadyStarted`, if an
            # instance already exists with same workflow id.
            rpc :StartWorkflowExecution, ::Temporalio::Api::WorkflowService::V1::StartWorkflowExecutionRequest, ::Temporalio::Api::WorkflowService::V1::StartWorkflowExecutionResponse
            # GetWorkflowExecutionHistory returns the history of specified workflow execution. Fails with
            # `NotFound` if the specified workflow execution is unknown to the service.
            rpc :GetWorkflowExecutionHistory, ::Temporalio::Api::WorkflowService::V1::GetWorkflowExecutionHistoryRequest, ::Temporalio::Api::WorkflowService::V1::GetWorkflowExecutionHistoryResponse
            # GetWorkflowExecutionHistoryReverse returns the history of specified workflow execution in reverse 
            # order (starting from last event). Fails with`NotFound` if the specified workflow execution is 
            # unknown to the service.
            rpc :GetWorkflowExecutionHistoryReverse, ::Temporalio::Api::WorkflowService::V1::GetWorkflowExecutionHistoryReverseRequest, ::Temporalio::Api::WorkflowService::V1::GetWorkflowExecutionHistoryReverseResponse
            # PollWorkflowTaskQueue is called by workers to make progress on workflows.
            #
            # A WorkflowTask is dispatched to callers for active workflow executions with pending workflow
            # tasks. The worker is expected to call `RespondWorkflowTaskCompleted` when it is done
            # processing the task. The service will create a `WorkflowTaskStarted` event in the history for
            # this task before handing it to the worker.
            rpc :PollWorkflowTaskQueue, ::Temporalio::Api::WorkflowService::V1::PollWorkflowTaskQueueRequest, ::Temporalio::Api::WorkflowService::V1::PollWorkflowTaskQueueResponse
            # RespondWorkflowTaskCompleted is called by workers to successfully complete workflow tasks
            # they received from `PollWorkflowTaskQueue`.
            #
            # Completing a WorkflowTask will write a `WORKFLOW_TASK_COMPLETED` event to the workflow's
            # history, along with events corresponding to whatever commands the SDK generated while
            # executing the task (ex timer started, activity task scheduled, etc).
            rpc :RespondWorkflowTaskCompleted, ::Temporalio::Api::WorkflowService::V1::RespondWorkflowTaskCompletedRequest, ::Temporalio::Api::WorkflowService::V1::RespondWorkflowTaskCompletedResponse
            # RespondWorkflowTaskFailed is called by workers to indicate the processing of a workflow task
            # failed.
            #
            # This results in a `WORKFLOW_TASK_FAILED` event written to the history, and a new workflow
            # task will be scheduled. This API can be used to report unhandled failures resulting from
            # applying the workflow task.
            #
            # Temporal will only append first WorkflowTaskFailed event to the history of workflow execution
            # for consecutive failures.
            rpc :RespondWorkflowTaskFailed, ::Temporalio::Api::WorkflowService::V1::RespondWorkflowTaskFailedRequest, ::Temporalio::Api::WorkflowService::V1::RespondWorkflowTaskFailedResponse
            # PollActivityTaskQueue is called by workers to process activity tasks from a specific task
            # queue.
            #
            # The worker is expected to call one of the `RespondActivityTaskXXX` methods when it is done
            # processing the task.
            #
            # An activity task is dispatched whenever a `SCHEDULE_ACTIVITY_TASK` command is produced during
            # workflow execution. An in memory `ACTIVITY_TASK_STARTED` event is written to mutable state
            # before the task is dispatched to the worker. The started event, and the final event
            # (`ACTIVITY_TASK_COMPLETED` / `ACTIVITY_TASK_FAILED` / `ACTIVITY_TASK_TIMED_OUT`) will both be
            # written permanently to Workflow execution history when Activity is finished. This is done to
            # avoid writing many events in the case of a failure/retry loop.
            rpc :PollActivityTaskQueue, ::Temporalio::Api::WorkflowService::V1::PollActivityTaskQueueRequest, ::Temporalio::Api::WorkflowService::V1::PollActivityTaskQueueResponse
            # RecordActivityTaskHeartbeat is optionally called by workers while they execute activities.
            #
            # If worker fails to heartbeat within the `heartbeat_timeout` interval for the activity task,
            # then it will be marked as timed out and an `ACTIVITY_TASK_TIMED_OUT` event will be written to
            # the workflow history. Calling `RecordActivityTaskHeartbeat` will fail with `NotFound` in
            # such situations, in that event, the SDK should request cancellation of the activity.
            rpc :RecordActivityTaskHeartbeat, ::Temporalio::Api::WorkflowService::V1::RecordActivityTaskHeartbeatRequest, ::Temporalio::Api::WorkflowService::V1::RecordActivityTaskHeartbeatResponse
            # See `RecordActivityTaskHeartbeat`. This version allows clients to record heartbeats by
            # namespace/workflow id/activity id instead of task token.
            #
            # (-- api-linter: core::0136::prepositions=disabled
            #     aip.dev/not-precedent: "By" is used to indicate request type. --)
            rpc :RecordActivityTaskHeartbeatById, ::Temporalio::Api::WorkflowService::V1::RecordActivityTaskHeartbeatByIdRequest, ::Temporalio::Api::WorkflowService::V1::RecordActivityTaskHeartbeatByIdResponse
            # RespondActivityTaskCompleted is called by workers when they successfully complete an activity
            # task.
            #
            # This results in a new `ACTIVITY_TASK_COMPLETED` event being written to the workflow history
            # and a new workflow task created for the workflow. Fails with `NotFound` if the task token is
            # no longer valid due to activity timeout, already being completed, or never having existed.
            rpc :RespondActivityTaskCompleted, ::Temporalio::Api::WorkflowService::V1::RespondActivityTaskCompletedRequest, ::Temporalio::Api::WorkflowService::V1::RespondActivityTaskCompletedResponse
            # See `RecordActivityTaskCompleted`. This version allows clients to record completions by
            # namespace/workflow id/activity id instead of task token.
            #
            # (-- api-linter: core::0136::prepositions=disabled
            #     aip.dev/not-precedent: "By" is used to indicate request type. --)
            rpc :RespondActivityTaskCompletedById, ::Temporalio::Api::WorkflowService::V1::RespondActivityTaskCompletedByIdRequest, ::Temporalio::Api::WorkflowService::V1::RespondActivityTaskCompletedByIdResponse
            # RespondActivityTaskFailed is called by workers when processing an activity task fails.
            #
            # This results in a new `ACTIVITY_TASK_FAILED` event being written to the workflow history and
            # a new workflow task created for the workflow. Fails with `NotFound` if the task token is no
            # longer valid due to activity timeout, already being completed, or never having existed.
            rpc :RespondActivityTaskFailed, ::Temporalio::Api::WorkflowService::V1::RespondActivityTaskFailedRequest, ::Temporalio::Api::WorkflowService::V1::RespondActivityTaskFailedResponse
            # See `RecordActivityTaskFailed`. This version allows clients to record failures by
            # namespace/workflow id/activity id instead of task token.
            #
            # (-- api-linter: core::0136::prepositions=disabled
            #     aip.dev/not-precedent: "By" is used to indicate request type. --)
            rpc :RespondActivityTaskFailedById, ::Temporalio::Api::WorkflowService::V1::RespondActivityTaskFailedByIdRequest, ::Temporalio::Api::WorkflowService::V1::RespondActivityTaskFailedByIdResponse
            # RespondActivityTaskFailed is called by workers when processing an activity task fails.
            #
            # This results in a new `ACTIVITY_TASK_CANCELED` event being written to the workflow history
            # and a new workflow task created for the workflow. Fails with `NotFound` if the task token is
            # no longer valid due to activity timeout, already being completed, or never having existed.
            rpc :RespondActivityTaskCanceled, ::Temporalio::Api::WorkflowService::V1::RespondActivityTaskCanceledRequest, ::Temporalio::Api::WorkflowService::V1::RespondActivityTaskCanceledResponse
            # See `RecordActivityTaskCanceled`. This version allows clients to record failures by
            # namespace/workflow id/activity id instead of task token.
            #
            # (-- api-linter: core::0136::prepositions=disabled
            #     aip.dev/not-precedent: "By" is used to indicate request type. --)
            rpc :RespondActivityTaskCanceledById, ::Temporalio::Api::WorkflowService::V1::RespondActivityTaskCanceledByIdRequest, ::Temporalio::Api::WorkflowService::V1::RespondActivityTaskCanceledByIdResponse
            # RequestCancelWorkflowExecution is called by workers when they want to request cancellation of
            # a workflow execution.
            #
            # This results in a new `WORKFLOW_EXECUTION_CANCEL_REQUESTED` event being written to the
            # workflow history and a new workflow task created for the workflow. It returns success if the requested
            # workflow is already closed. It fails with 'NotFound' if the requested workflow doesn't exist.
            rpc :RequestCancelWorkflowExecution, ::Temporalio::Api::WorkflowService::V1::RequestCancelWorkflowExecutionRequest, ::Temporalio::Api::WorkflowService::V1::RequestCancelWorkflowExecutionResponse
            # SignalWorkflowExecution is used to send a signal to a running workflow execution.
            #
            # This results in a `WORKFLOW_EXECUTION_SIGNALED` event recorded in the history and a workflow
            # task being created for the execution.
            rpc :SignalWorkflowExecution, ::Temporalio::Api::WorkflowService::V1::SignalWorkflowExecutionRequest, ::Temporalio::Api::WorkflowService::V1::SignalWorkflowExecutionResponse
            # SignalWithStartWorkflowExecution is used to ensure a signal is sent to a workflow, even if
            # it isn't yet started.
            #
            # If the workflow is running, a `WORKFLOW_EXECUTION_SIGNALED` event is recorded in the history
            # and a workflow task is generated.
            #
            # If the workflow is not running or not found, then the workflow is created with
            # `WORKFLOW_EXECUTION_STARTED` and `WORKFLOW_EXECUTION_SIGNALED` events in its history, and a
            # workflow task is generated.
            #
            # (-- api-linter: core::0136::prepositions=disabled
            #     aip.dev/not-precedent: "With" is used to indicate combined operation. --)
            rpc :SignalWithStartWorkflowExecution, ::Temporalio::Api::WorkflowService::V1::SignalWithStartWorkflowExecutionRequest, ::Temporalio::Api::WorkflowService::V1::SignalWithStartWorkflowExecutionResponse
            # ResetWorkflowExecution will reset an existing workflow execution to a specified
            # `WORKFLOW_TASK_COMPLETED` event (exclusive). It will immediately terminate the current
            # execution instance.
            # TODO: Does exclusive here mean *just* the completed event, or also WFT started? Otherwise the task is doomed to time out?
            rpc :ResetWorkflowExecution, ::Temporalio::Api::WorkflowService::V1::ResetWorkflowExecutionRequest, ::Temporalio::Api::WorkflowService::V1::ResetWorkflowExecutionResponse
            # TerminateWorkflowExecution terminates an existing workflow execution by recording a
            # `WORKFLOW_EXECUTION_TERMINATED` event in the history and immediately terminating the
            # execution instance.
            rpc :TerminateWorkflowExecution, ::Temporalio::Api::WorkflowService::V1::TerminateWorkflowExecutionRequest, ::Temporalio::Api::WorkflowService::V1::TerminateWorkflowExecutionResponse
            # DeleteWorkflowExecution asynchronously deletes a specific Workflow Execution (when
            # WorkflowExecution.run_id is provided) or the latest Workflow Execution (when
            # WorkflowExecution.run_id is not provided). If the Workflow Execution is Running, it will be
            # terminated before deletion.
            # (-- api-linter: core::0135::method-signature=disabled
            #     aip.dev/not-precedent: DeleteNamespace RPC doesn't follow Google API format. --)
            # (-- api-linter: core::0135::response-message-name=disabled
            #     aip.dev/not-precedent: DeleteNamespace RPC doesn't follow Google API format. --)
            rpc :DeleteWorkflowExecution, ::Temporalio::Api::WorkflowService::V1::DeleteWorkflowExecutionRequest, ::Temporalio::Api::WorkflowService::V1::DeleteWorkflowExecutionResponse
            # ListOpenWorkflowExecutions is a visibility API to list the open executions in a specific namespace.
            rpc :ListOpenWorkflowExecutions, ::Temporalio::Api::WorkflowService::V1::ListOpenWorkflowExecutionsRequest, ::Temporalio::Api::WorkflowService::V1::ListOpenWorkflowExecutionsResponse
            # ListClosedWorkflowExecutions is a visibility API to list the closed executions in a specific namespace.
            rpc :ListClosedWorkflowExecutions, ::Temporalio::Api::WorkflowService::V1::ListClosedWorkflowExecutionsRequest, ::Temporalio::Api::WorkflowService::V1::ListClosedWorkflowExecutionsResponse
            # ListWorkflowExecutions is a visibility API to list workflow executions in a specific namespace.
            rpc :ListWorkflowExecutions, ::Temporalio::Api::WorkflowService::V1::ListWorkflowExecutionsRequest, ::Temporalio::Api::WorkflowService::V1::ListWorkflowExecutionsResponse
            # ListArchivedWorkflowExecutions is a visibility API to list archived workflow executions in a specific namespace.
            rpc :ListArchivedWorkflowExecutions, ::Temporalio::Api::WorkflowService::V1::ListArchivedWorkflowExecutionsRequest, ::Temporalio::Api::WorkflowService::V1::ListArchivedWorkflowExecutionsResponse
            # ScanWorkflowExecutions is a visibility API to list large amount of workflow executions in a specific namespace without order.
            rpc :ScanWorkflowExecutions, ::Temporalio::Api::WorkflowService::V1::ScanWorkflowExecutionsRequest, ::Temporalio::Api::WorkflowService::V1::ScanWorkflowExecutionsResponse
            # CountWorkflowExecutions is a visibility API to count of workflow executions in a specific namespace.
            rpc :CountWorkflowExecutions, ::Temporalio::Api::WorkflowService::V1::CountWorkflowExecutionsRequest, ::Temporalio::Api::WorkflowService::V1::CountWorkflowExecutionsResponse
            # GetSearchAttributes is a visibility API to get all legal keys that could be used in list APIs
            rpc :GetSearchAttributes, ::Temporalio::Api::WorkflowService::V1::GetSearchAttributesRequest, ::Temporalio::Api::WorkflowService::V1::GetSearchAttributesResponse
            # RespondQueryTaskCompleted is called by workers to complete queries which were delivered on
            # the `query` (not `queries`) field of a `PollWorkflowTaskQueueResponse`.
            #
            # Completing the query will unblock the corresponding client call to `QueryWorkflow` and return
            # the query result a response.
            rpc :RespondQueryTaskCompleted, ::Temporalio::Api::WorkflowService::V1::RespondQueryTaskCompletedRequest, ::Temporalio::Api::WorkflowService::V1::RespondQueryTaskCompletedResponse
            # ResetStickyTaskQueue resets the sticky task queue related information in the mutable state of
            # a given workflow. This is prudent for workers to perform if a workflow has been paged out of
            # their cache.
            #
            # Things cleared are:
            # 1. StickyTaskQueue
            # 2. StickyScheduleToStartTimeout
            rpc :ResetStickyTaskQueue, ::Temporalio::Api::WorkflowService::V1::ResetStickyTaskQueueRequest, ::Temporalio::Api::WorkflowService::V1::ResetStickyTaskQueueResponse
            # QueryWorkflow requests a query be executed for a specified workflow execution.
            rpc :QueryWorkflow, ::Temporalio::Api::WorkflowService::V1::QueryWorkflowRequest, ::Temporalio::Api::WorkflowService::V1::QueryWorkflowResponse
            # DescribeWorkflowExecution returns information about the specified workflow execution.
            rpc :DescribeWorkflowExecution, ::Temporalio::Api::WorkflowService::V1::DescribeWorkflowExecutionRequest, ::Temporalio::Api::WorkflowService::V1::DescribeWorkflowExecutionResponse
            # DescribeTaskQueue returns information about the target task queue.
            rpc :DescribeTaskQueue, ::Temporalio::Api::WorkflowService::V1::DescribeTaskQueueRequest, ::Temporalio::Api::WorkflowService::V1::DescribeTaskQueueResponse
            # GetClusterInfo returns information about temporal cluster
            rpc :GetClusterInfo, ::Temporalio::Api::WorkflowService::V1::GetClusterInfoRequest, ::Temporalio::Api::WorkflowService::V1::GetClusterInfoResponse
            # GetSystemInfo returns information about the system.
            rpc :GetSystemInfo, ::Temporalio::Api::WorkflowService::V1::GetSystemInfoRequest, ::Temporalio::Api::WorkflowService::V1::GetSystemInfoResponse
            rpc :ListTaskQueuePartitions, ::Temporalio::Api::WorkflowService::V1::ListTaskQueuePartitionsRequest, ::Temporalio::Api::WorkflowService::V1::ListTaskQueuePartitionsResponse
            # Creates a new schedule.
            # (-- api-linter: core::0133::method-signature=disabled
            #     aip.dev/not-precedent: CreateSchedule doesn't follow Google API format --)
            # (-- api-linter: core::0133::response-message-name=disabled
            #     aip.dev/not-precedent: CreateSchedule doesn't follow Google API format --)
            # (-- api-linter: core::0133::http-uri-parent=disabled
            #     aip.dev/not-precedent: CreateSchedule doesn't follow Google API format --)
            rpc :CreateSchedule, ::Temporalio::Api::WorkflowService::V1::CreateScheduleRequest, ::Temporalio::Api::WorkflowService::V1::CreateScheduleResponse
            # Returns the schedule description and current state of an existing schedule.
            rpc :DescribeSchedule, ::Temporalio::Api::WorkflowService::V1::DescribeScheduleRequest, ::Temporalio::Api::WorkflowService::V1::DescribeScheduleResponse
            # Changes the configuration or state of an existing schedule.
            # (-- api-linter: core::0134::response-message-name=disabled
            #     aip.dev/not-precedent: UpdateSchedule RPC doesn't follow Google API format. --)
            # (-- api-linter: core::0134::method-signature=disabled
            #     aip.dev/not-precedent: UpdateSchedule RPC doesn't follow Google API format. --)
            rpc :UpdateSchedule, ::Temporalio::Api::WorkflowService::V1::UpdateScheduleRequest, ::Temporalio::Api::WorkflowService::V1::UpdateScheduleResponse
            # Makes a specific change to a schedule or triggers an immediate action.
            # (-- api-linter: core::0134::synonyms=disabled
            #     aip.dev/not-precedent: we have both patch and update. --)
            rpc :PatchSchedule, ::Temporalio::Api::WorkflowService::V1::PatchScheduleRequest, ::Temporalio::Api::WorkflowService::V1::PatchScheduleResponse
            # Lists matching times within a range.
            rpc :ListScheduleMatchingTimes, ::Temporalio::Api::WorkflowService::V1::ListScheduleMatchingTimesRequest, ::Temporalio::Api::WorkflowService::V1::ListScheduleMatchingTimesResponse
            # Deletes a schedule, removing it from the system.
            # (-- api-linter: core::0135::method-signature=disabled
            #     aip.dev/not-precedent: DeleteSchedule doesn't follow Google API format --)
            # (-- api-linter: core::0135::response-message-name=disabled
            #     aip.dev/not-precedent: DeleteSchedule doesn't follow Google API format --)
            rpc :DeleteSchedule, ::Temporalio::Api::WorkflowService::V1::DeleteScheduleRequest, ::Temporalio::Api::WorkflowService::V1::DeleteScheduleResponse
            # List all schedules in a namespace.
            rpc :ListSchedules, ::Temporalio::Api::WorkflowService::V1::ListSchedulesRequest, ::Temporalio::Api::WorkflowService::V1::ListSchedulesResponse
            # Allows users to specify sets of worker build id versions on a per task queue basis. Versions
            # are ordered, and may be either compatible with some extant version, or a new incompatible
            # version, forming sets of ids which are incompatible with each other, but whose contained
            # members are compatible with one another.
            #
            # (-- api-linter: core::0134::response-message-name=disabled
            #     aip.dev/not-precedent: UpdateWorkerBuildIdCompatibility RPC doesn't follow Google API format. --)
            # (-- api-linter: core::0134::method-signature=disabled
            #     aip.dev/not-precedent: UpdateWorkerBuildIdCompatibility RPC doesn't follow Google API format. --)
            rpc :UpdateWorkerBuildIdCompatibility, ::Temporalio::Api::WorkflowService::V1::UpdateWorkerBuildIdCompatibilityRequest, ::Temporalio::Api::WorkflowService::V1::UpdateWorkerBuildIdCompatibilityResponse
            # Fetches the worker build id versioning sets for some task queue and related metadata.
            rpc :GetWorkerBuildIdCompatibility, ::Temporalio::Api::WorkflowService::V1::GetWorkerBuildIdCompatibilityRequest, ::Temporalio::Api::WorkflowService::V1::GetWorkerBuildIdCompatibilityResponse
            # Invokes the specified update function on user workflow code.
            # (-- api-linter: core::0134=disabled
            #     aip.dev/not-precedent: UpdateWorkflowExecution doesn't follow Google API format --)
            rpc :UpdateWorkflowExecution, ::Temporalio::Api::WorkflowService::V1::UpdateWorkflowExecutionRequest, ::Temporalio::Api::WorkflowService::V1::UpdateWorkflowExecutionResponse
            # Polls a workflow execution for the outcome of a workflow execution update
            # previously issued through the UpdateWorkflowExecution RPC. The effective
            # timeout on this call will be shorter of the the caller-supplied gRPC
            # timeout and the server's configured long-poll timeout.
            # (-- api-linter: core::0134=disabled
            #     aip.dev/not-precedent: UpdateWorkflowExecution doesn't follow Google API format --)
            rpc :PollWorkflowExecutionUpdate, ::Temporalio::Api::WorkflowService::V1::PollWorkflowExecutionUpdateRequest, ::Temporalio::Api::WorkflowService::V1::PollWorkflowExecutionUpdateResponse
            # StartBatchOperation starts a new batch operation
            rpc :StartBatchOperation, ::Temporalio::Api::WorkflowService::V1::StartBatchOperationRequest, ::Temporalio::Api::WorkflowService::V1::StartBatchOperationResponse
            # StopBatchOperation stops a batch operation
            rpc :StopBatchOperation, ::Temporalio::Api::WorkflowService::V1::StopBatchOperationRequest, ::Temporalio::Api::WorkflowService::V1::StopBatchOperationResponse
            # DescribeBatchOperation returns the information about a batch operation
            rpc :DescribeBatchOperation, ::Temporalio::Api::WorkflowService::V1::DescribeBatchOperationRequest, ::Temporalio::Api::WorkflowService::V1::DescribeBatchOperationResponse
            # ListBatchOperations returns a list of batch operations
            rpc :ListBatchOperations, ::Temporalio::Api::WorkflowService::V1::ListBatchOperationsRequest, ::Temporalio::Api::WorkflowService::V1::ListBatchOperationsResponse
          end

          Stub = Service.rpc_stub_class
        end
      end
    end
  end
end
