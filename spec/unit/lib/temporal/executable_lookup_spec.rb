require 'temporal/executable_lookup'

describe Temporal::ExecutableLookup do
  class TestClass; end

  describe '#add' do
    it 'adds a class to the lookup map' do
      subject.add('foo', TestClass)

      expect(subject.send(:executables)).to eq('foo' => TestClass)
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
  end
end
