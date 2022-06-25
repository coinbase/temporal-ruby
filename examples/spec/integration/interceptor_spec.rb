require 'workflows/hello_world_workflow'

describe 'GRPC interceptors', :integration do
  class ExampleInterceptor < GRPC::ClientInterceptor
    attr_reader :called_methods

    def initialize
      @called_methods = []
    end

    def request_response(request: nil, call: nil, method: nil, metadata: nil)
      @called_methods << method
      yield
    end
  end

  def run_workflow_with_client(client, workflow, *input, **args)
    args[:options] = { workflow_id: SecureRandom.uuid }.merge(args[:options] || {})
    run_id = client.start_workflow(workflow, *input, **args)

    [args[:options][:workflow_id], run_id]
  end

  let(:interceptor) { ExampleInterceptor.new }
  let(:config) do
    # We can't depend on test order here and the memoized
    # Temporal.default_client will not include our interceptors. Therefore we
    # build a new config and client based on the one used in the other tests.
    common_config = Temporal.configuration
    Temporal::Configuration.new.tap do |config|
      config.host = common_config.host
      config.port = common_config.port
      config.namespace = common_config.namespace
      config.task_queue = common_config.task_queue
      config.metrics_adapter = common_config.metrics_adapter
      config.interceptors = [interceptor]
    end
  end
  let(:client) { Temporal::Client.new(config) }

  it 'calls the given interceptors when performing operations' do
    workflow_id, run_id = run_workflow_with_client(client, HelloWorldWorkflow, 'Tom')
    client.await_workflow_result(
      HelloWorldWorkflow,
      workflow_id: workflow_id,
      run_id: run_id
    )

    expect(interceptor.called_methods).to match_array([
      "/temporal.api.workflowservice.v1.WorkflowService/StartWorkflowExecution",
      "/temporal.api.workflowservice.v1.WorkflowService/GetWorkflowExecutionHistory",
    ])
  end
end
