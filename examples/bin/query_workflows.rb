#!/usr/bin/env ruby
require_relative '../init'
require 'grpc'
require 'time'
require 'google/protobuf/well_known_types'
require 'securerandom'
require 'temporal/connection/errors'
require 'temporal/connection/serializer'
require 'temporal/connection/serializer/failure'
require 'gen/temporal/api/workflowservice/v1/service_services_pb'
require 'temporal/concerns/payloads'

# puts Temporal.list_open_workflow_executions('ruby-samples', Time.now - 100*60*60)

puts Temporal.list_closed_workflow_executions('ruby-samples', Time.now - 100*60*60, filter: {status: Temporal::Workflow::Status::COMPLETED})

# puts Temporal::Api::Enums::V1::WorkflowExecutionStatus.resolve(:WORKFLOW_EXECUTION_STATUS_RUNNING)

# puts Temporal::Api::Filter::V1::StatusFilter.methods