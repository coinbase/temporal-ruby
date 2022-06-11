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

  let(:interceptor) { ExampleInterceptor.new }

  around(:each) do |example|
    Temporal.configure do |config|
      config.interceptors = [interceptor]
    end

    example.run
  ensure
    Temporal.configure do |config|
      config.interceptors = []
    end
  end

  it 'calls the given interceptors when performing operations' do
    workflow_id, run_id = run_workflow(HelloWorldWorkflow, 'Tom')
    wait_for_workflow_completion(workflow_id, run_id)

    expect(interceptor.called_methods).to match_array([
      "/temporal.api.workflowservice.v1.WorkflowService/StartWorkflowExecution",
      "/temporal.api.workflowservice.v1.WorkflowService/GetWorkflowExecutionHistory",
    ])
  end
end
