require 'workflows/hello_world_workflow'
require 'lib/crypt_payload_codec'
require 'grpc/errors'

describe 'Converter', :integration do
  around(:each) do |example|
    task_queue = Temporal.configuration.task_queue

    Temporal.configure do |config|
      config.task_queue = 'crypt'
      config.payload_codec = Temporal::Connection::Converter::Codec::Chain.new(
        payload_codecs: [
          Temporal::CryptPayloadCodec.new
        ]
      )
    end

    example.run
  ensure
    Temporal.configure do |config|
      config.task_queue = task_queue
      config.payload_codec = Temporal::Configuration::DEFAULT_PAYLOAD_CODEC
    end
  end

  it 'can encrypt payloads' do
    workflow_id, run_id = run_workflow(HelloWorldWorkflow, 'Tom')

    begin
      wait_for_workflow_completion(workflow_id, run_id)
    rescue GRPC::DeadlineExceeded
      raise "Encrypted-payload workflow didn't run.  Make sure you run USE_ENCRYPTION=1 ./bin/worker and try again."
    end

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

    expect(Temporal.configuration.converter.from_payloads(result)&.first).to eq('Hello World, Tom')
  end
end
