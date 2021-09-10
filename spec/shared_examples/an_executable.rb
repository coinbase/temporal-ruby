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
      described_class.instance_variable_set(:@retry_policy, :test)

      expect(described_class.retry_policy).to eq(:test)
    end

    it 'sets new valid retry policy' do
      described_class.retry_policy(:test)

      expect(described_class.instance_variable_get(:@retry_policy)).to eq(:test)
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
