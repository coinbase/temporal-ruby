require 'temporal/connection/serializer/failure'
require 'temporal/workflow/command'

describe Temporal::Connection::Serializer::Failure do
  let(:converter) do
    Temporal::ConverterWrapper.new(
      Temporal::Configuration::DEFAULT_CONVERTER,
      Temporal::Configuration::DEFAULT_PAYLOAD_CODEC
    )
  end

  describe 'to_proto' do
    it 'produces a protobuf' do
      result = described_class.new(StandardError.new('test'), converter).to_proto

      expect(result).to be_an_instance_of(Temporalio::Api::Failure::V1::Failure)
    end

    class NaughtyClass; end

    class MyError < StandardError
      attr_reader :foo, :bad_class

      def initialize(foo, bar, bad_class:)
        @foo = foo
        @bad_class = bad_class

        # Ensure that we serialize derived properties.
        my_message = "Hello, #{bar}!"
        super(my_message)
      end
    end

    it 'Serializes round-trippable full errors when asked to' do
      # Make sure serializing various bits round-trips
      e = MyError.new(['seven', 'three'], "Bar", bad_class: NaughtyClass)
      failure_proto = described_class.new(e, converter, serialize_whole_error: true).to_proto
      expect(failure_proto.application_failure_info.type).to eq("MyError")

      deserialized_error = converter.from_details_payloads(failure_proto.application_failure_info.details)
      expect(deserialized_error).to be_an_instance_of(MyError)
      expect(deserialized_error.message).to eq("Hello, Bar!")
      expect(deserialized_error.foo).to eq(['seven', 'three'])
      expect(deserialized_error.bad_class).to eq(NaughtyClass)
    end

    class MyBigError < StandardError
      attr_reader :big_payload
      def initialize(message)
        super(message)
        @big_payload = '123456789012345678901234567890123456789012345678901234567890'
      end
    end


    it 'deals with too-large serialization using the old path' do
      e = MyBigError.new('Uh oh!')
      # Normal serialization path
      failure_proto = described_class.new(e, converter, serialize_whole_error: true, max_bytes: 1000).to_proto
      expect(failure_proto.application_failure_info.type).to eq('MyBigError')
      deserialized_error = converter.from_details_payloads(failure_proto.application_failure_info.details)
      expect(deserialized_error).to be_an_instance_of(MyBigError)
      expect(deserialized_error.big_payload).to eq('123456789012345678901234567890123456789012345678901234567890')

      # Exercise legacy serialization mechanism
      failure_proto = described_class.new(e, converter, serialize_whole_error: false).to_proto
      expect(failure_proto.application_failure_info.type).to eq('MyBigError')
      old_style_deserialized_error = MyBigError.new(converter.from_details_payloads(failure_proto.application_failure_info.details))
      expect(old_style_deserialized_error).to be_an_instance_of(MyBigError)
      expect(old_style_deserialized_error.message).to eq('Uh oh!')

      # If the payload size exceeds the max_bytes, we fallback to the old-style serialization.
      failure_proto = described_class.new(e, converter, serialize_whole_error: true, max_bytes: 50).to_proto
      expect(failure_proto.application_failure_info.type).to eq('MyBigError')
      avoids_truncation_error = MyBigError.new(converter.from_details_payloads(failure_proto.application_failure_info.details))
      expect(avoids_truncation_error).to be_an_instance_of(MyBigError)
      expect(avoids_truncation_error.message).to eq('Uh oh!')

      # Fallback serialization should exactly match legacy serialization
      expect(avoids_truncation_error).to eq(old_style_deserialized_error)
    end

    it 'logs a helpful error when the payload is too large' do 
      e = MyBigError.new('Uh oh!')

      allow(Temporal.logger).to receive(:error)
      max_bytes = 50
      described_class.new(e, converter, serialize_whole_error: true, max_bytes: max_bytes).to_proto
      expect(Temporal.logger)
        .to have_received(:error)
        .with(
          "Could not serialize exception because it's too large, so we are using a fallback that may not deserialize "\
          "correctly on the client.  First #{max_bytes} bytes:\n{\"^o\":\"MyBigError\",\"big_payload\":\"1234567890123456",
          { unserializable_error: 'MyBigError' }
        )

    end

    class MyArglessError < RuntimeError
      def initialize; end
    end

    it 'successfully processes an error with no constructor arguments' do 
      e = MyArglessError.new
      failure_proto = described_class.new(e, converter, serialize_whole_error: true).to_proto
      expect(failure_proto.application_failure_info.type).to eq('MyArglessError')
    end

  end
end
