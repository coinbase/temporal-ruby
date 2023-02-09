require 'temporal/connection/serializer/failure'
require 'temporal/workflow/command'

class TestDeserializer
  include Temporal::Concerns::Payloads
end

describe Temporal::Connection::Serializer::Failure do
  describe 'to_proto' do
    it 'produces a protobuf' do
      result = described_class.new(StandardError.new('test')).to_proto

      expect(result).to be_an_instance_of(Temporal::Api::Failure::V1::Failure)
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
      failure_proto = described_class.new(e, serialize_whole_error: true).to_proto
      expect(failure_proto.application_failure_info.type).to eq("MyError")

      deserialized_error = TestDeserializer.new.from_details_payloads(failure_proto.application_failure_info.details)
      expect(deserialized_error).to be_an_instance_of(MyError)
      expect(deserialized_error.message).to eq("Hello, Bar!")
      expect(deserialized_error.foo).to eq(['seven', 'three'])
      expect(deserialized_error.bad_class).to eq(NaughtyClass)
    end

  end
end
