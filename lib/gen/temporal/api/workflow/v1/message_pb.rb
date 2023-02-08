# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: temporal/api/workflow/v1/message.proto

require 'google/protobuf'

require 'google/protobuf/duration_pb'
require 'google/protobuf/timestamp_pb'
require 'dependencies/gogoproto/gogo_pb'
require 'temporal/api/enums/v1/workflow_pb'
require 'temporal/api/common/v1/message_pb'
require 'temporal/api/failure/v1/message_pb'
require 'temporal/api/taskqueue/v1/message_pb'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("temporal/api/workflow/v1/message.proto", :syntax => :proto3) do
    add_message "temporal.api.workflow.v1.WorkflowExecutionInfo" do
      optional :execution, :message, 1, "temporal.api.common.v1.WorkflowExecution"
      optional :type, :message, 2, "temporal.api.common.v1.WorkflowType"
      optional :start_time, :message, 3, "google.protobuf.Timestamp"
      optional :close_time, :message, 4, "google.protobuf.Timestamp"
      optional :status, :enum, 5, "temporal.api.enums.v1.WorkflowExecutionStatus"
      optional :history_length, :int64, 6
      optional :parent_namespace_id, :string, 7
      optional :parent_execution, :message, 8, "temporal.api.common.v1.WorkflowExecution"
      optional :execution_time, :message, 9, "google.protobuf.Timestamp"
      optional :memo, :message, 10, "temporal.api.common.v1.Memo"
      optional :search_attributes, :message, 11, "temporal.api.common.v1.SearchAttributes"
      optional :auto_reset_points, :message, 12, "temporal.api.workflow.v1.ResetPoints"
      optional :task_queue, :string, 13
      optional :state_transition_count, :int64, 14
      optional :history_size_bytes, :int64, 15
    end
    add_message "temporal.api.workflow.v1.WorkflowExecutionConfig" do
      optional :task_queue, :message, 1, "temporal.api.taskqueue.v1.TaskQueue"
      optional :workflow_execution_timeout, :message, 2, "google.protobuf.Duration"
      optional :workflow_run_timeout, :message, 3, "google.protobuf.Duration"
      optional :default_workflow_task_timeout, :message, 4, "google.protobuf.Duration"
    end
    add_message "temporal.api.workflow.v1.PendingActivityInfo" do
      optional :activity_id, :string, 1
      optional :activity_type, :message, 2, "temporal.api.common.v1.ActivityType"
      optional :state, :enum, 3, "temporal.api.enums.v1.PendingActivityState"
      optional :heartbeat_details, :message, 4, "temporal.api.common.v1.Payloads"
      optional :last_heartbeat_time, :message, 5, "google.protobuf.Timestamp"
      optional :last_started_time, :message, 6, "google.protobuf.Timestamp"
      optional :attempt, :int32, 7
      optional :maximum_attempts, :int32, 8
      optional :scheduled_time, :message, 9, "google.protobuf.Timestamp"
      optional :expiration_time, :message, 10, "google.protobuf.Timestamp"
      optional :last_failure, :message, 11, "temporal.api.failure.v1.Failure"
      optional :last_worker_identity, :string, 12
    end
    add_message "temporal.api.workflow.v1.PendingChildExecutionInfo" do
      optional :workflow_id, :string, 1
      optional :run_id, :string, 2
      optional :workflow_type_name, :string, 3
      optional :initiated_id, :int64, 4
      optional :parent_close_policy, :enum, 5, "temporal.api.enums.v1.ParentClosePolicy"
    end
    add_message "temporal.api.workflow.v1.PendingWorkflowTaskInfo" do
      optional :state, :enum, 1, "temporal.api.enums.v1.PendingWorkflowTaskState"
      optional :scheduled_time, :message, 2, "google.protobuf.Timestamp"
      optional :original_scheduled_time, :message, 3, "google.protobuf.Timestamp"
      optional :started_time, :message, 4, "google.protobuf.Timestamp"
      optional :attempt, :int32, 5
    end
    add_message "temporal.api.workflow.v1.ResetPoints" do
      repeated :points, :message, 1, "temporal.api.workflow.v1.ResetPointInfo"
    end
    add_message "temporal.api.workflow.v1.ResetPointInfo" do
      optional :binary_checksum, :string, 1
      optional :run_id, :string, 2
      optional :first_workflow_task_completed_id, :int64, 3
      optional :create_time, :message, 4, "google.protobuf.Timestamp"
      optional :expire_time, :message, 5, "google.protobuf.Timestamp"
      optional :resettable, :bool, 6
    end
    add_message "temporal.api.workflow.v1.NewWorkflowExecutionInfo" do
      optional :workflow_id, :string, 1
      optional :workflow_type, :message, 2, "temporal.api.common.v1.WorkflowType"
      optional :task_queue, :message, 3, "temporal.api.taskqueue.v1.TaskQueue"
      optional :input, :message, 4, "temporal.api.common.v1.Payloads"
      optional :workflow_execution_timeout, :message, 5, "google.protobuf.Duration"
      optional :workflow_run_timeout, :message, 6, "google.protobuf.Duration"
      optional :workflow_task_timeout, :message, 7, "google.protobuf.Duration"
      optional :workflow_id_reuse_policy, :enum, 8, "temporal.api.enums.v1.WorkflowIdReusePolicy"
      optional :retry_policy, :message, 9, "temporal.api.common.v1.RetryPolicy"
      optional :cron_schedule, :string, 10
      optional :memo, :message, 11, "temporal.api.common.v1.Memo"
      optional :search_attributes, :message, 12, "temporal.api.common.v1.SearchAttributes"
      optional :header, :message, 13, "temporal.api.common.v1.Header"
    end
  end
end

module Temporalio
  module Api
    module Workflow
      module V1
        WorkflowExecutionInfo = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.workflow.v1.WorkflowExecutionInfo").msgclass
        WorkflowExecutionConfig = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.workflow.v1.WorkflowExecutionConfig").msgclass
        PendingActivityInfo = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.workflow.v1.PendingActivityInfo").msgclass
        PendingChildExecutionInfo = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.workflow.v1.PendingChildExecutionInfo").msgclass
        PendingWorkflowTaskInfo = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.workflow.v1.PendingWorkflowTaskInfo").msgclass
        ResetPoints = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.workflow.v1.ResetPoints").msgclass
        ResetPointInfo = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.workflow.v1.ResetPointInfo").msgclass
        NewWorkflowExecutionInfo = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.workflow.v1.NewWorkflowExecutionInfo").msgclass
      end
    end
  end
end
