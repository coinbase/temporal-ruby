PROTO_ROOT := proto
PROTO_FILES = $(shell find $(PROTO_ROOT) -name "*.proto")
PROTO_DIRS = $(sort $(dir $(PROTO_FILES)))
PROTO_OUT := lib/gen
PROTO_TESTING_ROOT := lib/temporal/testing/proto
PROTO_TESTING_FILES = $(shell find $(PROTO_TESTING_ROOT) -name "*.proto")
PROTO_TESTING_DIRS = $(sort $(dir $(PROTO_TESTING_FILES)))

proto:
	$(foreach PROTO_DIR,$(PROTO_DIRS),bundle exec grpc_tools_ruby_protoc -Iproto --ruby_out=$(PROTO_OUT) --grpc_out=$(PROTO_OUT) $(PROTO_DIR)*.proto;)

proto-testing:
	$(foreach PROTO_DIR,$(PROTO_TESTING_DIRS),bundle exec grpc_tools_ruby_protoc --proto_path="lib/temporal/testing/proto" --ruby_out=$(PROTO_OUT) --grpc_out=$(PROTO_OUT) $(PROTO_DIR)*.proto;)

.PHONY: proto, proto-testing