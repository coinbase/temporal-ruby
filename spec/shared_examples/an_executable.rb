shared_examples 'an executable' do
  describe '.domain' do
    after { described_class.remove_instance_variable(:@domain) }

    it 'gets current domain' do
      described_class.instance_variable_set(:@domain, :test)

      expect(described_class.domain).to eq(:test)
    end

    it 'sets new domain' do
      described_class.domain(:test)

      expect(described_class.instance_variable_get(:@domain)).to eq(:test)
    end
  end

  describe '.task_list' do
    after { described_class.remove_instance_variable(:@task_list) }

    it 'gets current task list' do
      described_class.instance_variable_set(:@task_list, :test)

      expect(described_class.task_list).to eq(:test)
    end

    it 'sets new task list' do
      described_class.task_list(:test)

      expect(described_class.instance_variable_get(:@task_list)).to eq(:test)
    end
  end

  describe '.retry_policy' do
    after { described_class.remove_instance_variable(:@retry_policy) }

    it 'gets current retry policy' do
      retry_policy = Cadence::RetryPolicy.new
      described_class.instance_variable_set(:@retry_policy, retry_policy)

      expect(described_class.retry_policy).to eq(retry_policy)
    end

    it 'sets new valid retry policy' do
      policy = { interval: 1, backoff: 1, max_attempts: 3 }
      described_class.retry_policy(policy)

      expect(described_class.instance_variable_get(:@retry_policy))
        .to eq(Cadence::RetryPolicy.new(policy))
    end

    it 'raises when setting invalid retry policy' do
      expect do
        described_class.retry_policy(interval: 0.1)
      end.to raise_error(Cadence::RetryPolicy::InvalidRetryPolicy)
    end
  end

  describe '.timeouts' do
    after { described_class.remove_instance_variable(:@timeouts) }

    it 'gets current timeouts' do
      described_class.instance_variable_set(:@timeouts, :test)

      expect(described_class.timeouts).to eq(:test)
    end

    it 'sets new timeouts' do
      described_class.timeouts(:test)

      expect(described_class.instance_variable_get(:@timeouts)).to eq(:test)
    end
  end
end
