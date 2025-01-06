PROTO_ROOT := .
PROTO_FILES = $(shell find $(PROTO_ROOT) -name "*.proto")
PROTO_DIRS = $(sort $(dir $(PROTO_FILES)))
PROTO_OUT := .gen

$(PROTO_OUT):
	mkdir $(PROTO_OUT)

proto-testing:
	$(foreach PROTO_DIR,$(PROTO_DIRS),bundle exec grpc_tools_ruby_protoc --ruby_out=$(PROTO_OUT) --grpc_out=$(PROTO_OUT) $(PROTO_DIR)*.proto;)

.PHONY: proto-testing
