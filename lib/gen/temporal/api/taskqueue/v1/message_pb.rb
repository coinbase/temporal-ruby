# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: temporal/api/taskqueue/v1/message.proto

require 'google/protobuf'

require 'google/protobuf/duration_pb'
require 'google/protobuf/timestamp_pb'
require 'google/protobuf/wrappers_pb'
require 'dependencies/gogoproto/gogo_pb'
require 'temporal/api/enums/v1/task_queue_pb'
require 'temporal/api/common/v1/message_pb'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("temporal/api/taskqueue/v1/message.proto", :syntax => :proto3) do
    add_message "temporal.api.taskqueue.v1.TaskQueue" do
      optional :name, :string, 1
      optional :kind, :enum, 2, "temporal.api.enums.v1.TaskQueueKind"
    end
    add_message "temporal.api.taskqueue.v1.TaskQueueMetadata" do
      optional :max_tasks_per_second, :message, 1, "google.protobuf.DoubleValue"
    end
    add_message "temporal.api.taskqueue.v1.TaskQueueStatus" do
      optional :backlog_count_hint, :int64, 1
      optional :read_level, :int64, 2
      optional :ack_level, :int64, 3
      optional :rate_per_second, :double, 4
      optional :task_id_block, :message, 5, "temporal.api.taskqueue.v1.TaskIdBlock"
    end
    add_message "temporal.api.taskqueue.v1.TaskIdBlock" do
      optional :start_id, :int64, 1
      optional :end_id, :int64, 2
    end
    add_message "temporal.api.taskqueue.v1.TaskQueuePartitionMetadata" do
      optional :key, :string, 1
      optional :owner_host_name, :string, 2
    end
    add_message "temporal.api.taskqueue.v1.PollerInfo" do
      optional :last_access_time, :message, 1, "google.protobuf.Timestamp"
      optional :identity, :string, 2
      optional :rate_per_second, :double, 3
      optional :worker_version_capabilities, :message, 4, "temporal.api.common.v1.WorkerVersionCapabilities"
    end
    add_message "temporal.api.taskqueue.v1.StickyExecutionAttributes" do
      optional :worker_task_queue, :message, 1, "temporal.api.taskqueue.v1.TaskQueue"
      optional :schedule_to_start_timeout, :message, 2, "google.protobuf.Duration"
    end
    add_message "temporal.api.taskqueue.v1.CompatibleVersionSet" do
      optional :version_set_id, :string, 1
      repeated :build_ids, :string, 2
    end
  end
end

module Temporalio
  module Api
    module TaskQueue
      module V1
        TaskQueue = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.taskqueue.v1.TaskQueue").msgclass
        TaskQueueMetadata = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.taskqueue.v1.TaskQueueMetadata").msgclass
        TaskQueueStatus = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.taskqueue.v1.TaskQueueStatus").msgclass
        TaskIdBlock = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.taskqueue.v1.TaskIdBlock").msgclass
        TaskQueuePartitionMetadata = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.taskqueue.v1.TaskQueuePartitionMetadata").msgclass
        PollerInfo = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.taskqueue.v1.PollerInfo").msgclass
        StickyExecutionAttributes = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.taskqueue.v1.StickyExecutionAttributes").msgclass
        CompatibleVersionSet = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.taskqueue.v1.CompatibleVersionSet").msgclass
      end
    end
  end
end
