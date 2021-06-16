require 'temporal/client/serializer/failure'
require 'temporal/workflow/command'

describe Temporal::Client::Serializer::Failure do
  describe 'to_proto' do
    it 'produces a protobuf' do
      result = described_class.new(StandardError.new('test')).to_proto

      expect(result).to be_an_instance_of(Temporal::Api::Failure::V1::Failure)
    end
  end
end
