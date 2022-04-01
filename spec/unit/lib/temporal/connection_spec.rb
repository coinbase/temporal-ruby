require 'temporal/connection'
require 'temporal/configuration'

describe Temporal::Connection do
  let(:config) { Temporal::Configuration.new }

  describe '.generate' do
    before { allow(Temporal::Connection::GRPC).to receive(:new) }

    it 'generates a new GRPC conection' do
      described_class.generate(config.for_connection)

      expect(Temporal::Connection::GRPC)
        .to have_received(:new)
        .with(config.host, config.port, an_instance_of(String), config.converter)
    end
  end
end
