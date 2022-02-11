# Purpose

This pattern is useful for when a business process needs to track inputs from
multiple different places. It allows for a main workflow to track the overall progress
and maintain the journey status. Each input is handled by a separate workflow which
receives the input and then signals that input to the main workflow to update its
state. The main workflow then responds back to the other workflow which can exit and
return a complex value to its caller. 

The caller could potentially Query the main workflow to get results. Having these secondary
workflows return a response to the caller seems cleaner and more logical.

# Errors

```ruby
gems/grpc-1.43.1/src/ruby/lib/grpc/generic/active_call.rb:29:in `check_status': 5:5:sql: no rows in result set. debug_error_string:{"created":"@1643644553.347306000","description":"Error received from peer ipv6:[::1]:7233","file":"src/core/lib/surface/call.cc","file_line":1075,"grpc_message":"sql: no rows in result set","grpc_status":5} (GRPC::NotFound)
	from /Users/ChuckRemes/.gem/ruby/3.1.0/gems/grpc-1.43.1/src/ruby/lib/grpc/generic/active_call.rb:180:in `attach_status_results_and_complete_call'
	from /Users/ChuckRemes/.gem/ruby/3.1.0/gems/grpc-1.43.1/src/ruby/lib/grpc/generic/active_call.rb:376:in `request_response'
	from /Users/ChuckRemes/.gem/ruby/3.1.0/gems/grpc-1.43.1/src/ruby/lib/grpc/generic/client_stub.rb:180:in `block in request_response'
	from /Users/ChuckRemes/.gem/ruby/3.1.0/gems/grpc-1.43.1/src/ruby/lib/grpc/generic/interceptors.rb:170:in `intercept!'
	from /Users/ChuckRemes/.gem/ruby/3.1.0/gems/grpc-1.43.1/src/ruby/lib/grpc/generic/client_stub.rb:179:in `request_response'
	from /Users/ChuckRemes/.gem/ruby/3.1.0/gems/grpc-1.43.1/src/ruby/lib/grpc/generic/service.rb:171:in `block (3 levels) in rpc_stub_class'
	from /Users/ChuckRemes/temporal-ruby/lib/temporal/connection/grpc.rb:296:in `signal_workflow_execution'
	from /Users/ChuckRemes/temporal-ruby/lib/temporal/client.rb:158:in `signal_workflow'
	from /Users/ChuckRemes/.rubies/ruby-3.1.0/lib/ruby/3.1.0/forwardable.rb:238:in `signal_workflow'
```

This error is raised when a `run_id` is passed to `Temporal.signal_workflow` instead of a `workflow_id`.
Note that the call to `Temporal.start_workflow` returns a `run_id` as its value. Unless a workflow_id
was set in the workflow_options and passed to that command, getting the execution info for the workflow
is impossible. The `namespace`, `workflow_id`, and `run_id` are necessary to get any workflow_execution_info.
It's best practice to always set workflow_id when starting a workflow otherwise finding information on
it later is difficult.
