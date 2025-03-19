require 'temporal/executable_lookup'
require 'temporal/concerns/executable'

describe Temporal::ExecutableLookup do
  class TestClass
    extend Temporal::Concerns::Executable
  end

  class MyDynamicActivity
    extend Temporal::Concerns::Executable
  end

  class IllegalSecondDynamicActivity
    extend Temporal::Concerns::Executable
  end

  describe '#add' do
    it 'adds a class to the lookup map' do
      subject.add('foo', TestClass)

      expect(subject.send(:executables)).to eq('foo' => "TestClass")
    end
  end

  describe '#add_dynamic' do
    it 'fails on the second dynamic activity' do
      subject.add_dynamic('MyDynamicActivity', MyDynamicActivity)
      expect do
        subject.add_dynamic('IllegalSecondDynamicActivity', IllegalSecondDynamicActivity)
      end.to raise_error(Temporal::ExecutableLookup::SecondDynamicExecutableError)
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

    it "still returns the class even it was unloaded and has a new object_id" do
      original_object_id = stub_const('TestClass', Class.new).object_id
      subject.add('foo', TestClass)

      expected_class = stub_const('TestClass', Class.new)

      expect(expected_class.object_id).not_to eq(original_object_id)
      expect(subject.find('foo')).to be(expected_class)
    end

    it 'falls back to the dynamic executable' do
      subject.add('TestClass', TestClass)
      subject.add_dynamic('MyDynamicActivity', MyDynamicActivity)

      expect(subject.find('TestClass')).to eq(TestClass)
      expect(subject.find('SomethingElse')).to eq(MyDynamicActivity)
    end
  end
end
