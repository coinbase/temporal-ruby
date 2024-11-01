# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: temporal/api/filter/v1/message.proto

require 'google/protobuf'

require 'google/protobuf/timestamp_pb'
require 'temporal/api/enums/v1/workflow_pb'


descriptor_data = "\n$temporal/api/filter/v1/message.proto\x12\x16temporal.api.filter.v1\x1a\x1fgoogle/protobuf/timestamp.proto\x1a$temporal/api/enums/v1/workflow.proto\">\n\x17WorkflowExecutionFilter\x12\x13\n\x0bworkflow_id\x18\x01 \x01(\t\x12\x0e\n\x06run_id\x18\x02 \x01(\t\"\"\n\x12WorkflowTypeFilter\x12\x0c\n\x04name\x18\x01 \x01(\t\"u\n\x0fStartTimeFilter\x12\x31\n\rearliest_time\x18\x01 \x01(\x0b\x32\x1a.google.protobuf.Timestamp\x12/\n\x0blatest_time\x18\x02 \x01(\x0b\x32\x1a.google.protobuf.Timestamp\"N\n\x0cStatusFilter\x12>\n\x06status\x18\x01 \x01(\x0e\x32..temporal.api.enums.v1.WorkflowExecutionStatusB\x89\x01\n\x19io.temporal.api.filter.v1B\x0cMessageProtoP\x01Z#go.temporal.io/api/filter/v1;filter\xaa\x02\x18Temporalio.Api.Filter.V1\xea\x02\x1bTemporalio::Api::Filter::V1b\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

module Temporalio
  module Api
    module Filter
      module V1
        WorkflowExecutionFilter = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.filter.v1.WorkflowExecutionFilter").msgclass
        WorkflowTypeFilter = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.filter.v1.WorkflowTypeFilter").msgclass
        StartTimeFilter = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.filter.v1.StartTimeFilter").msgclass
        StatusFilter = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.filter.v1.StatusFilter").msgclass
      end
    end
  end
end
