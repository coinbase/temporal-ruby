require 'temporal/activity'

describe Temporal::Logger do
  subject { described_class.new(STDERR) }

  describe '.execute_in_context' do
    before do
      allow(subject).to receive(:add)
    end

    it 'accepts data argument to log method' do
      subject.log(Logger::DEBUG, 'test', { a: 1 })

      expect(subject).to have_received(:add).with(Logger::DEBUG, 'test {"a":1}')
    end

    it 'accepts data argument to debug method' do
      subject.debug('test', { a: 1 })

      expect(subject).to have_received(:add).with(Logger::DEBUG, nil, 'test {"a":1}')
    end

    it 'accepts data argument to info method' do
      subject.info('test', { a: 1 })

      expect(subject).to have_received(:add).with(Logger::INFO, nil, 'test {"a":1}')
    end

    it 'accepts data argument to warn method' do
      subject.warn('test', { a: 1 })

      expect(subject).to have_received(:add).with(Logger::WARN, nil, 'test {"a":1}')
    end

    it 'accepts data argument to error method' do
      subject.error('test', { a: 1 })

      expect(subject).to have_received(:add).with(Logger::ERROR, nil, 'test {"a":1}')
    end

    it 'accepts data argument to fatal method' do
      subject.fatal('test', { a: 1 })

      expect(subject).to have_received(:add).with(Logger::FATAL, nil, 'test {"a":1}')
    end

    it 'accepts data argument to unknown method' do
      subject.unknown('test', { a: 1 })

      expect(subject).to have_received(:add).with(Logger::UNKNOWN, nil, 'test {"a":1}')
    end
  end
end
