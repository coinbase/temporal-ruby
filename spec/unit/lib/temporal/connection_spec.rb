describe Temporal::Connection do
  subject { described_class.generate(config.for_connection) }

  let(:connection_type) { :grpc }
  let(:credentials) { nil }
  let(:config) do
    config = Temporal::Configuration.new
    config.connection_type = connection_type
    config.credentials = credentials if credentials
    config
  end

  context 'client_config' do
    let(:client_config) { { channel_args: { 'foo' => 'again' } } }
    let(:expected_client_config) { Temporal::Configuration::GRPCConfig.new(client_config) }

    it 'overrides' do
      config.client_config = client_config
      expect(subject.send(:client_config)).to eq(expected_client_config)
    end
  end

  context 'identity' do
    let(:identity) { 'my_identity' }
    it 'overrides' do
      config.identity = identity
      expect(subject.send(:identity)).to eq(identity)
    end
  end

  context 'insecure' do
    let(:credentials) { :this_channel_is_insecure }

    it 'generates a grpc connection' do
      expect(subject).to be_kind_of(Temporal::Connection::GRPC)
      expect(subject.send(:identity)).not_to be_nil
      expect(subject.send(:credentials)).to eq(:this_channel_is_insecure)
    end
  end

  context 'ssl' do
    let(:credentials) { GRPC::Core::ChannelCredentials.new }

    it 'generates a grpc connection' do
      expect(subject).to be_kind_of(Temporal::Connection::GRPC)
      expect(subject.send(:identity)).not_to be_nil
      expect(subject.send(:credentials)).to be_kind_of(GRPC::Core::ChannelCredentials)
    end
  end

  context 'oauth2' do
    let(:credentials) { GRPC::Core::CallCredentials.new(proc { { authorization: 'token' } }) }

    it 'generates a grpc connection' do
      expect(subject).to be_kind_of(Temporal::Connection::GRPC)
      expect(subject.send(:identity)).not_to be_nil
      expect(subject.send(:credentials)).to be_kind_of(GRPC::Core::CallCredentials)
    end
  end

  context 'ssl + oauth2' do
    let(:credentials) do
      GRPC::Core::ChannelCredentials.new.compose(
        GRPC::Core::CallCredentials.new(
          proc { { authorization: 'token' } }
        )
      )
    end

    it 'generates a grpc connection' do
      expect(subject).to be_kind_of(Temporal::Connection::GRPC)
      expect(subject.send(:identity)).not_to be_nil
      expect(subject.send(:credentials)).to be_kind_of(GRPC::Core::ChannelCredentials)
    end
  end
end
