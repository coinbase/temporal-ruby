# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: temporal/api/protocol/v1/message.proto

require 'google/protobuf'

require 'google/protobuf/any_pb'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("temporal/api/protocol/v1/message.proto", :syntax => :proto3) do
    add_message "temporal.api.protocol.v1.Message" do
      optional :id, :string, 1
      optional :protocol_instance_id, :string, 2
      optional :body, :message, 5, "google.protobuf.Any"
      oneof :sequencing_id do
        optional :event_id, :int64, 3
        optional :command_index, :int64, 4
      end
    end
  end
end

module Temporalio
  module Api
    module Protocol
      module V1
        Message = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.protocol.v1.Message").msgclass
      end
    end
  end
end
