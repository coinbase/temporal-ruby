require 'workflows/hello_world_workflow'
require 'lib/cryptconverter'

describe 'Converter', :integration do
  around(:each) do
    previous_config = Temporal.configuration

    Temporal.configure do |config|
      config.task_queue = 'crypt'
      config.converter = Temporal::Client::Converter::Crypt.new(
        payload_converter: Temporal::Configuration::DEFAULT_CONVERTER
      )
    end

    yield
  ensure
    Temporal.configuration = previous_config
  end

  it 'can encrypt payloads' do
    result = run_workflow(HelloWorldWorkflow)

    event = result.history.events.first
    expect(event.event_type).to eq(:EVENT_TYPE_WORKFLOW_EXECUTION_COMPLETED)

    encrypted_payloads = event.workflow_execution_completed_event_attributes.result

    expect(encrypted_payloads.payloads.first.metadata['encoding']).to eq('binary/encrypted')
  end
end
