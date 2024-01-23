require 'workflows/hello_world_workflow'
require 'lib/crypt_payload_codec'
require 'grpc/errors'

describe 'Converter', :integration do
  let(:config) do
    Temporal.configuration.dup.tap do |config|
      config.task_queue = 'crypt'
      config.payload_codec = Temporal::Connection::Converter::Codec::Chain.new(
        payload_codecs: [
          Temporal::CryptPayloadCodec.new
        ]
      )
    end
  end
  let(:client) { Temporal::Client.new(config) }

  it 'can encrypt payloads' do
    workflow_id = SecureRandom.uuid
    run_id = client.start_workflow(HelloWorldWorkflow, 'Tom', options: { workflow_id: workflow_id })

    begin
      client.await_workflow_result(HelloWorldWorkflow, workflow_id: workflow_id, run_id: run_id)
    rescue GRPC::DeadlineExceeded
      raise "Encrypted-payload workflow didn't run.  Make sure you run USE_ENCRYPTION=1 ./bin/worker and try again."
    end

    history = client.get_workflow_history(namespace: config.namespace, workflow_id: workflow_id, run_id: run_id)

    events = history.events.group_by(&:type)

    events['WORKFLOW_EXECUTION_STARTED'].map do |event|
      input = event.attributes.input
      input.payloads.each do |payload|
        expect(payload.metadata['encoding']).to eq('binary/encrypted')
      end
    end

    events['ACTIVITY_TASK_SCHEDULED'].map do |event|
      input = event.attributes.input
      input.payloads.each do |payload|
        expect(payload.metadata['encoding']).to eq('binary/encrypted')
      end
    end

    events['ACTIVITY_TASK_COMPLETED'].map do |event|
      result = event.attributes.result
      result.payloads.each do |payload|
        expect(payload.metadata['encoding']).to eq('binary/encrypted')
      end
    end

    events['WORKFLOW_EXECUTION_COMPLETED'].map do |event|
      result = event.attributes.result
      result.payloads.each do |payload|
        expect(payload.metadata['encoding']).to eq('binary/encrypted')
      end
    end

    completion_event = events['WORKFLOW_EXECUTION_COMPLETED'].first
    result = completion_event.attributes.result

    expect(config.converter.from_payloads(result)&.first).to eq('Hello World, Tom')
  end
end
