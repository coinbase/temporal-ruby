require 'temporal'

describe Temporal do
  describe 'public method forwarding' do
    let(:client) { instance_double(Temporal::Client) }

    before { allow(Temporal::Client).to receive(:new).and_return(client) }
    after { described_class.remove_instance_variable(:@default_client) rescue NameError }

    shared_examples 'a forwarded method' do |method, *args, kwargs|
      it 'forwards a method call to the default client instance' do
        allow(client).to receive(method)

        described_class.public_send(method, *args, kwargs)

        expect(client).to have_received(method).with(*args, kwargs)
      end
    end
    
    describe '.start_workflow' do
      it_behaves_like 'a forwarded method', :start_workflow, 'TestWorkflow', 42
    end    
    
    describe '.schedule_workflow' do
      it_behaves_like 'a forwarded method', :schedule_workflow, 'TestWorkflow', '* * * * *', 42
    end    
    
    describe '.register_namespace' do
      it_behaves_like 'a forwarded method', :register_namespace, 'test-namespace', 'This is a test namespace'
    end

    describe '.describe_namespace' do
      it_behaves_like 'a forwarded method', :describe_namespace, 'test-namespace'
    end
    
    describe '.signal_workflow' do
      it_behaves_like 'a forwarded method', :signal_workflow, 'TestWorkflow', 'TST_SIGNAL', 'x', 'y'
    end
    
    describe '.await_workflow_result' do
      it_behaves_like 'a forwarded method', :await_workflow_result, 'TestWorkflow', workflow_id: 'x'
    end
    
    describe '.reset_workflow' do
      it_behaves_like 'a forwarded method', :reset_workflow, 'test-namespace', 'x', 'y'
    end

    describe '.terminate_workflow' do
      it_behaves_like 'a forwarded method', :terminate_workflow, 'x'
    end

    describe '.fetch_workflow_execution_info' do
      it_behaves_like 'a forwarded method', :fetch_workflow_execution_info, 'test-namespace', 'x', 'y'
    end

    describe '.complete_activity' do
      it_behaves_like 'a forwarded method', :complete_activity, 'test-token', 'result'
    end

    describe '.fail_activity' do
      it_behaves_like 'a forwarded method', :complete_activity, 'test-token', StandardError.new
    end

    describe '.get_workflow_history' do
      it_behaves_like 'a forwarded method', :get_workflow_history, 'test-namespace', 'x', 'y'
    end
  end

  describe '.configure' do
    it 'calls a block with the configuration' do
      expect do |block|
        described_class.configure(&block)
      end.to yield_with_args(described_class.configuration)
    end
  end

  describe '.configuration' do
    it 'returns Temporal::Configuration object' do
      expect(described_class.configuration).to be_an_instance_of(Temporal::Configuration)
    end
  end

  describe '.logger' do
    it 'returns preconfigured Temporal logger' do
      expect(described_class.logger).to eq(described_class.configuration.logger)
    end
  end
  
  describe '.metrics' do
    it 'returns preconfigured Temporal metrics' do
      expect(described_class.metrics).to an_instance_of(Temporal::Metrics)
    end
  end
end
