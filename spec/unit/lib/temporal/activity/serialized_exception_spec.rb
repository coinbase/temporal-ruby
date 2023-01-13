require 'temporal/activity/serialized_exception'
require 'temporal/json'

describe Temporal::Activity::SerializedException do
  class MyError < Temporal::ActivityException

    attr_reader :foo, :bar

    def initialize(foo, bar:)
      @foo = foo
      @bar = bar
    end

    def serialize_args
      # Users can use whatever serialization they would like
      Temporal::JSON.serialize({'foo' => @foo, 'bar' => @bar})
    end

    def self.from_serialized_args(value)
      hash = Temporal::JSON.deserialize(value)
      MyError.new(hash['foo'], bar: hash['bar'])
    end

  end

  it 'Can round-trip' do
    error = MyError.new(['seven', 'three'], bar: 5)
    marshalling_error = described_class.from_activity_exception(error)
    expect(marshalling_error).to be_a(described_class)

    client_error = described_class.to_activity_exception(marshalling_error.message)
    expect(client_error).to be_a(MyError)
    expect(client_error.foo).to eq(['seven', 'three'])
    expect(client_error.bar).to eq(5)
  end

  class NotAnActivityExceptionError < StandardError; end

  it 'rejects non-ActivityException errors' do
    expect do
      described_class.from_activity_exception(NotAnActivityExceptionError.new)
    end.to raise_error(ArgumentError)
  end

  # doesn't override serialize/from_serialized_args
  class MyActivityException < Temporal::ActivityException; end

  it 'no-ops on a non-customized ActivityException' do
    error = MyActivityException.new("some message")
    marshalling_error = described_class.from_activity_exception(error)
    expect(marshalling_error).to be_a(MyActivityException)

  end
end
