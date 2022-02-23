describe Temporal::Connection do
  subject { described_class.generate(config.for_connection) }

  let(:connection_type) { :unknown }
  let(:credentials) { nil }
  let(:config) do
    config = Temporal::Configuration.new
    config.connection_type = connection_type
    config.credentials = credentials if credentials
    config
  end

  context 'grpc' do
    let(:connection_type) { :grpc }

    it 'generates a grpc connection' do
      expect(subject).to be_kind_of(Temporal::Connection::GRPC)
      expect(subject.send(:identity)).not_to be_nil
      expect(subject.send(:credentials)).to eq(:this_channel_is_insecure)
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
  end
end
