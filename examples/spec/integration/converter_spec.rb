require 'workflows/hello_world_workflow'
require 'lib/cryptconverter'

describe 'Converter', :integration do
  around(:each) do |example|
    task_queue = Temporal.configuration.task_queue

    Temporal.configure do |config|
      config.task_queue = 'crypt'
      config.converter = Temporal::CryptConverter.new(
        payload_converter: Temporal::Configuration::DEFAULT_CONVERTER
      )
    end

    example.run
  ensure
    Temporal.configure do |config|
      config.task_queue = task_queue
      config.converter = Temporal::Configuration::DEFAULT_CONVERTER
    end
  end

  it 'can encrypt payloads' do
    workflow_id, run_id = run_workflow(HelloWorldWorkflow, 'Tom')

    wait_for_workflow_completion(workflow_id, run_id)

    result = fetch_history(workflow_id, run_id)

    events = result.history.events.group_by(&:event_type)

    events[:EVENT_TYPE_WORKFLOW_EXECUTION_STARTED].map do |event|
      input = event.workflow_execution_started_event_attributes.input
      input.payloads.each do |payload|
        expect(payload.metadata['encoding']).to eq('binary/encrypted')
      end
    end

    events[:EVENT_TYPE_ACTIVITY_TASK_SCHEDULED].map do |event|
      input = event.activity_task_scheduled_event_attributes.input
      input.payloads.each do |payload|
        expect(payload.metadata['encoding']).to eq('binary/encrypted')
      end
    end

    events[:EVENT_TYPE_ACTIVITY_TASK_COMPLETED].map do |event|
      result = event.activity_task_completed_event_attributes.result
      result.payloads.each do |payload|
        expect(payload.metadata['encoding']).to eq('binary/encrypted')
      end
    end

    events[:EVENT_TYPE_WORKFLOW_EXECUTION_COMPLETED].map do |event|
      result = event.workflow_execution_completed_event_attributes.result
      result.payloads.each do |payload|
        expect(payload.metadata['encoding']).to eq('binary/encrypted')
      end
    end

    completion_event = events[:EVENT_TYPE_WORKFLOW_EXECUTION_COMPLETED].first
    result = completion_event.workflow_execution_completed_event_attributes.result

    converter = Temporal.configuration.converter

    expect(converter.from_payloads(result)&.first).to eq('Hello World, Tom')
  end
end
