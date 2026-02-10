require 'temporal'

describe 'Temporal load order' do
  it 'loads payload concerns without gRPC' do
    expect(Temporal::Concerns::Payloads).to be_a(Module)
  end

  it 'loads serializer constants without gRPC' do
    expect(Temporal::Connection::Serializer::Failure).to be_a(Class)
  end

  it 'loads workflow error enums at boot' do
    expect(Temporal::Workflow::Errors::WORKFLOW_ALREADY_EXISTS_SYM).not_to be_nil
  end

  it 'loads workflow history event class at boot' do
    expect(Temporal::Workflow::History::Event).to be_a(Class)
  end
end
