PROTO_ROOT := proto
PROTO_FILES = $(shell find $(PROTO_ROOT) -name "*.proto")
PROTO_DIRS = $(sort $(dir $(PROTO_FILES)))
PROTO_OUT := lib/gen

proto:
	$(foreach PROTO_DIR,$(PROTO_DIRS),bundle exec grpc_tools_ruby_protoc -Iproto --ruby_out=$(PROTO_OUT) --grpc_out=$(PROTO_OUT) $(PROTO_DIR)*.proto;)

	# Need to only load imports if not disabled
	sed -i "/require 'temporal/ s|\(.*\)|\1 unless ENV['COINBASE_TEMPORAL_RUBY_DISABLE_PROTO_LOAD'] == '1'|" \
		lib/gen/temporal/api/operatorservice/v1/service_services_pb.rb
	sed -i "/require 'temporal/ s|\(.*\)|\1 unless ENV['COINBASE_TEMPORAL_RUBY_DISABLE_PROTO_LOAD'] == '1'|" \
		lib/gen/temporal/api/workflowservice/v1/service_services_pb.rb

.PHONY: proto
