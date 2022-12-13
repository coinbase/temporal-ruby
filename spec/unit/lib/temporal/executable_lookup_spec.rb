require 'temporal/executable_lookup'
require 'temporal/concerns/executable'

describe Temporal::ExecutableLookup do
  class TestClass
    extend Temporal::Concerns::Executable
  end

  class MyDynamicActivity
    extend Temporal::Concerns::Executable

    dynamic
  end

  class IllegalSecondDynamicActivity
    extend Temporal::Concerns::Executable

    dynamic
  end

  describe '#add' do
    it 'adds a class to the lookup map' do
      subject.add('foo', TestClass)

      expect(subject.send(:executables)).to eq('foo' => TestClass)
    end

    it 'fails on the second dynamic activity.' do
      subject.add('MyDynamicActivity', MyDynamicActivity)
      expect do
        subject.add('IllegalSecondDynamicActivity', IllegalSecondDynamicActivity)
      end.to raise_error(
        Temporal::TypeAlreadyRegisteredError,
        'Cannot register IllegalSecondDynamicActivity marked as dynamic; MyDynamicActivity is already registered as ' \
        'dynamic, and there can be only one.'
      )
    end
  end

  describe '#find' do
    before { subject.add('foo', TestClass) }

    it 'returns a looked up class' do
      expect(subject.find('foo')).to eq(TestClass)
    end

    it 'returns nil if there were no matches' do
      expect(subject.find('bar')).to eq(nil)
    end

    it 'falls back to the dynamic executable' do
      subject.add('TestClass', TestClass)
      subject.add('MyDynamicActivity', MyDynamicActivity)

      expect(subject.find('TestClass')).to eq(TestClass)
      expect(subject.find('SomethingElse')).to eq(MyDynamicActivity)
    end
  end
end
