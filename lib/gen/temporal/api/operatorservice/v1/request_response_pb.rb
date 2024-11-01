# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: temporal/api/operatorservice/v1/request_response.proto

require 'google/protobuf'

require 'temporal/api/enums/v1/common_pb'
require 'temporal/api/nexus/v1/message_pb'
require 'google/protobuf/duration_pb'


descriptor_data = "\n6temporal/api/operatorservice/v1/request_response.proto\x12\x1ftemporal.api.operatorservice.v1\x1a\"temporal/api/enums/v1/common.proto\x1a#temporal/api/nexus/v1/message.proto\x1a\x1egoogle/protobuf/duration.proto\"\xff\x01\n\x1a\x41\x64\x64SearchAttributesRequest\x12l\n\x11search_attributes\x18\x01 \x03(\x0b\x32Q.temporal.api.operatorservice.v1.AddSearchAttributesRequest.SearchAttributesEntry\x12\x11\n\tnamespace\x18\x02 \x01(\t\x1a`\n\x15SearchAttributesEntry\x12\x0b\n\x03key\x18\x01 \x01(\t\x12\x36\n\x05value\x18\x02 \x01(\x0e\x32\'.temporal.api.enums.v1.IndexedValueType:\x02\x38\x01\"\x1d\n\x1b\x41\x64\x64SearchAttributesResponse\"M\n\x1dRemoveSearchAttributesRequest\x12\x19\n\x11search_attributes\x18\x01 \x03(\t\x12\x11\n\tnamespace\x18\x02 \x01(\t\" \n\x1eRemoveSearchAttributesResponse\"0\n\x1bListSearchAttributesRequest\x12\x11\n\tnamespace\x18\x01 \x01(\t\"\xe2\x04\n\x1cListSearchAttributesResponse\x12n\n\x11\x63ustom_attributes\x18\x01 \x03(\x0b\x32S.temporal.api.operatorservice.v1.ListSearchAttributesResponse.CustomAttributesEntry\x12n\n\x11system_attributes\x18\x02 \x03(\x0b\x32S.temporal.api.operatorservice.v1.ListSearchAttributesResponse.SystemAttributesEntry\x12h\n\x0estorage_schema\x18\x03 \x03(\x0b\x32P.temporal.api.operatorservice.v1.ListSearchAttributesResponse.StorageSchemaEntry\x1a`\n\x15\x43ustomAttributesEntry\x12\x0b\n\x03key\x18\x01 \x01(\t\x12\x36\n\x05value\x18\x02 \x01(\x0e\x32\'.temporal.api.enums.v1.IndexedValueType:\x02\x38\x01\x1a`\n\x15SystemAttributesEntry\x12\x0b\n\x03key\x18\x01 \x01(\t\x12\x36\n\x05value\x18\x02 \x01(\x0e\x32\'.temporal.api.enums.v1.IndexedValueType:\x02\x38\x01\x1a\x34\n\x12StorageSchemaEntry\x12\x0b\n\x03key\x18\x01 \x01(\t\x12\r\n\x05value\x18\x02 \x01(\t:\x02\x38\x01\"|\n\x16\x44\x65leteNamespaceRequest\x12\x11\n\tnamespace\x18\x01 \x01(\t\x12\x14\n\x0cnamespace_id\x18\x02 \x01(\t\x12\x39\n\x16namespace_delete_delay\x18\x03 \x01(\x0b\x32\x19.google.protobuf.Duration\"4\n\x17\x44\x65leteNamespaceResponse\x12\x19\n\x11\x64\x65leted_namespace\x18\x01 \x01(\t\"\x84\x01\n\x1f\x41\x64\x64OrUpdateRemoteClusterRequest\x12\x18\n\x10\x66rontend_address\x18\x01 \x01(\t\x12(\n enable_remote_cluster_connection\x18\x02 \x01(\x08\x12\x1d\n\x15\x66rontend_http_address\x18\x03 \x01(\t\"\"\n AddOrUpdateRemoteClusterResponse\"2\n\x1aRemoveRemoteClusterRequest\x12\x14\n\x0c\x63luster_name\x18\x01 \x01(\t\"\x1d\n\x1bRemoveRemoteClusterResponse\"A\n\x13ListClustersRequest\x12\x11\n\tpage_size\x18\x01 \x01(\x05\x12\x17\n\x0fnext_page_token\x18\x02 \x01(\x0c\"s\n\x14ListClustersResponse\x12\x42\n\x08\x63lusters\x18\x01 \x03(\x0b\x32\x30.temporal.api.operatorservice.v1.ClusterMetadata\x12\x17\n\x0fnext_page_token\x18\x04 \x01(\x0c\"\xc0\x01\n\x0f\x43lusterMetadata\x12\x14\n\x0c\x63luster_name\x18\x01 \x01(\t\x12\x12\n\ncluster_id\x18\x02 \x01(\t\x12\x0f\n\x07\x61\x64\x64ress\x18\x03 \x01(\t\x12\x14\n\x0chttp_address\x18\x07 \x01(\t\x12 \n\x18initial_failover_version\x18\x04 \x01(\x03\x12\x1b\n\x13history_shard_count\x18\x05 \x01(\x05\x12\x1d\n\x15is_connection_enabled\x18\x06 \x01(\x08\"%\n\x17GetNexusEndpointRequest\x12\n\n\x02id\x18\x01 \x01(\t\"M\n\x18GetNexusEndpointResponse\x12\x31\n\x08\x65ndpoint\x18\x01 \x01(\x0b\x32\x1f.temporal.api.nexus.v1.Endpoint\"O\n\x1a\x43reateNexusEndpointRequest\x12\x31\n\x04spec\x18\x01 \x01(\x0b\x32#.temporal.api.nexus.v1.EndpointSpec\"P\n\x1b\x43reateNexusEndpointResponse\x12\x31\n\x08\x65ndpoint\x18\x01 \x01(\x0b\x32\x1f.temporal.api.nexus.v1.Endpoint\"l\n\x1aUpdateNexusEndpointRequest\x12\n\n\x02id\x18\x01 \x01(\t\x12\x0f\n\x07version\x18\x02 \x01(\x03\x12\x31\n\x04spec\x18\x03 \x01(\x0b\x32#.temporal.api.nexus.v1.EndpointSpec\"P\n\x1bUpdateNexusEndpointResponse\x12\x31\n\x08\x65ndpoint\x18\x01 \x01(\x0b\x32\x1f.temporal.api.nexus.v1.Endpoint\"9\n\x1a\x44\x65leteNexusEndpointRequest\x12\n\n\x02id\x18\x01 \x01(\t\x12\x0f\n\x07version\x18\x02 \x01(\x03\"\x1d\n\x1b\x44\x65leteNexusEndpointResponse\"U\n\x19ListNexusEndpointsRequest\x12\x11\n\tpage_size\x18\x01 \x01(\x05\x12\x17\n\x0fnext_page_token\x18\x02 \x01(\x0c\x12\x0c\n\x04name\x18\x03 \x01(\t\"i\n\x1aListNexusEndpointsResponse\x12\x17\n\x0fnext_page_token\x18\x01 \x01(\x0c\x12\x32\n\tendpoints\x18\x02 \x03(\x0b\x32\x1f.temporal.api.nexus.v1.EndpointB\xbe\x01\n\"io.temporal.api.operatorservice.v1B\x14RequestResponseProtoP\x01Z5go.temporal.io/api/operatorservice/v1;operatorservice\xaa\x02!Temporalio.Api.OperatorService.V1\xea\x02$Temporalio::Api::OperatorService::V1b\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

module Temporalio
  module Api
    module OperatorService
      module V1
        AddSearchAttributesRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.AddSearchAttributesRequest").msgclass
        AddSearchAttributesResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.AddSearchAttributesResponse").msgclass
        RemoveSearchAttributesRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.RemoveSearchAttributesRequest").msgclass
        RemoveSearchAttributesResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.RemoveSearchAttributesResponse").msgclass
        ListSearchAttributesRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.ListSearchAttributesRequest").msgclass
        ListSearchAttributesResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.ListSearchAttributesResponse").msgclass
        DeleteNamespaceRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.DeleteNamespaceRequest").msgclass
        DeleteNamespaceResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.DeleteNamespaceResponse").msgclass
        AddOrUpdateRemoteClusterRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.AddOrUpdateRemoteClusterRequest").msgclass
        AddOrUpdateRemoteClusterResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.AddOrUpdateRemoteClusterResponse").msgclass
        RemoveRemoteClusterRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.RemoveRemoteClusterRequest").msgclass
        RemoveRemoteClusterResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.RemoveRemoteClusterResponse").msgclass
        ListClustersRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.ListClustersRequest").msgclass
        ListClustersResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.ListClustersResponse").msgclass
        ClusterMetadata = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.ClusterMetadata").msgclass
        GetNexusEndpointRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.GetNexusEndpointRequest").msgclass
        GetNexusEndpointResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.GetNexusEndpointResponse").msgclass
        CreateNexusEndpointRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.CreateNexusEndpointRequest").msgclass
        CreateNexusEndpointResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.CreateNexusEndpointResponse").msgclass
        UpdateNexusEndpointRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.UpdateNexusEndpointRequest").msgclass
        UpdateNexusEndpointResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.UpdateNexusEndpointResponse").msgclass
        DeleteNexusEndpointRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.DeleteNexusEndpointRequest").msgclass
        DeleteNexusEndpointResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.DeleteNexusEndpointResponse").msgclass
        ListNexusEndpointsRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.ListNexusEndpointsRequest").msgclass
        ListNexusEndpointsResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.operatorservice.v1.ListNexusEndpointsResponse").msgclass
      end
    end
  end
end
