require 'temporal/connection/serializer/failure'
require 'temporal/workflow/command'

describe Temporal::Connection::Serializer::Failure do
  let(:config) { Temporal::Configuration.new }

  describe 'to_proto' do
    it 'produces a protobuf' do
      result = described_class.new(StandardError.new('test'), config.converter).to_proto

      expect(result).to be_an_instance_of(Temporal::Api::Failure::V1::Failure)
    end
  end
end
