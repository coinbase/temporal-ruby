shared_examples 'an executable' do
  describe '.namespace' do
    after { described_class.remove_instance_variable(:@namespace) }

    it 'gets current namespace' do
      described_class.instance_variable_set(:@namespace, :test)

      expect(described_class.namespace).to eq(:test)
    end

    it 'sets new namespace' do
      described_class.namespace(:test)

      expect(described_class.instance_variable_get(:@namespace)).to eq(:test)
    end
  end

  describe '.task_queue' do
    after { described_class.remove_instance_variable(:@task_queue) }

    it 'gets current task list' do
      described_class.instance_variable_set(:@task_queue, :test)

      expect(described_class.task_queue).to eq(:test)
    end

    it 'sets new task list' do
      described_class.task_queue(:test)

      expect(described_class.instance_variable_get(:@task_queue)).to eq(:test)
    end
  end

  describe '.retry_policy' do
    after { described_class.remove_instance_variable(:@retry_policy) }

    it 'gets current retry policy' do
      retry_policy = Temporal::RetryPolicy.new
      described_class.instance_variable_set(:@retry_policy, retry_policy)

      expect(described_class.retry_policy).to eq(retry_policy)
    end

    it 'sets new valid retry policy' do
      policy = { initial_interval: 1, backoff_coefficient: 1, maximum_attempts: 3 }
      described_class.retry_policy(policy)

      expect(described_class.instance_variable_get(:@retry_policy))
        .to eq(Temporal::RetryPolicy.new(policy))
    end

    it 'raises when setting invalid retry policy' do
      expect do
        described_class.retry_policy(initial_interval: 0.1)
      end.to raise_error(Temporal::RetryPolicy::InvalidRetryPolicy)
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
