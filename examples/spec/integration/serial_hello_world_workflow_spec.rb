require 'workflows/serial_hello_world_workflow'

describe SerialHelloWorldWorkflow do
  subject { described_class }

  it 'works' do
    Temporal.configure do |config|
      config.host = 'temporal'
      config.port = 7233
      config.namespace = 'ruby-samples'
      config.task_queue = 'general'
    end

    workflow_id = SecureRandom.uuid
    run_id = Temporal.start_workflow(
      SerialHelloWorldWorkflow,
      'Alice',
      'Bob',
      'John',
      options: { workflow_id: workflow_id }
    )

    client = Temporal.send(:client)

    result = client.get_workflow_execution_history(
      namespace: Temporal.configuration.namespace,
      workflow_id: workflow_id,
      run_id: run_id,
      next_page_token: nil,
      wait_for_new_event: true,
      event_type: :close
    )

    expect(result.history.events.first.event_type).to eq(:EVENT_TYPE_WORKFLOW_EXECUTION_COMPLETED)
  end

  before { allow(HelloWorldActivity).to receive(:execute!).and_call_original }

  it 'executes HelloWorldActivity' do
    subject.execute_locally('Alice', 'Bob', 'John')

    expect(HelloWorldActivity).to have_received(:execute!).with('Alice').ordered
    expect(HelloWorldActivity).to have_received(:execute!).with('Bob').ordered
    expect(HelloWorldActivity).to have_received(:execute!).with('John').ordered
  end

  it 'returns nil' do
    expect(subject.execute_locally).to eq(nil)
  end
end
