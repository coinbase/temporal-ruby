require 'temporal/workflow/errors'

class ErrorWithTwoArgs < StandardError
  def initialize(message, another_argument); end
end

class ErrorThatRaisesInInitialize < StandardError
  def initialize(message)
    # This class simulates an error class that has bugs in its initialize method, or where
    # the arg isn't a string. It raises the sort of TypeError that would happen if you wrote
    # 1 + message
    raise TypeError.new("String can't be coerced into Integer")
  end
end

class SomeError < StandardError; end

class MyFancyError < Exception

  attr_reader :foo, :bar

  # Initializer doesn't just take one argument as StandardError does.
  def initialize(foo, bar)
    @foo = foo
    @bar = bar
  end
end

describe Temporal::Workflow::Errors do
  let(:converter) do
    Temporal::ConverterWrapper.new(
      Temporal::Configuration::DEFAULT_CONVERTER,
      Temporal::Configuration::DEFAULT_PAYLOAD_CODEC
    )
  end

  describe '.generate_error' do
    it "instantiates properly when the client has the error" do
      message = "An error message"
      stack_trace = ["a fake backtrace"]
      failure = Fabricate(
        :api_application_failure,
        message: message,
        backtrace: stack_trace,
        error_class: SomeError.to_s
      )

      e = Temporal::Workflow::Errors.generate_error(failure, converter)
      expect(e).to be_a(SomeError)
      expect(e.message).to eq(message)
      expect(e.backtrace).to eq(stack_trace)

    end

    it 'correctly deserializes a complex error' do
      error = MyFancyError.new('foo', 'bar')
      failure = Temporal::Connection::Serializer::Failure.new(error, converter, serialize_whole_error: true).to_proto

      e = Temporal::Workflow::Errors.generate_error(failure, converter)
      expect(e).to be_a(MyFancyError)
      expect(e.foo).to eq('foo')
      expect(e.bar).to eq('bar')
    end


    it "falls back to StandardError when the client doesn't have the error class" do
      allow(Temporal.logger).to receive(:error)

      message = "An error message"
      stack_trace = ["a fake backtrace"]
      failure = Fabricate(
        :api_application_failure,
        message: message,
        backtrace: stack_trace,
        error_class: 'NonexistentError',
      )

      e = Temporal::Workflow::Errors.generate_error(failure, converter)
      expect(e).to be_a(StandardError)
      expect(e.message).to eq("NonexistentError: An error message")
      expect(e.backtrace).to eq(stack_trace)
      expect(Temporal.logger)
        .to have_received(:error)
        .with(
          'Could not find original error class. Defaulting to StandardError.',
          {original_error: "NonexistentError"},
        )

    end


    it "falls back to StandardError when the client can't initialize the error class due to arity" do
      allow(Temporal.logger).to receive(:error)

      message = "An error message"
      stack_trace = ["a fake backtrace"]
      failure = Fabricate(
        :api_application_failure,
        message: message,
        backtrace: stack_trace,
        error_class: ErrorWithTwoArgs.to_s,
      )

      e = Temporal::Workflow::Errors.generate_error(failure, converter)
      expect(e).to be_a(StandardError)
      expect(e.message).to eq("ErrorWithTwoArgs: An error message")
      expect(e.backtrace).to eq(stack_trace)
      expect(Temporal.logger)
        .to have_received(:error)
        .with(
          "Could not instantiate original error. Defaulting to StandardError. "\
          "Make sure the worker running your activities is configured with use_error_serialization_v2. "\
          "If so, make sure the original error serialized by searching your logs for 'unserializable_error'. "\
          "If not, you're using legacy serialization, and it's likely that "\
          "your error's initializer takes something other than exactly one positional argument.",
          {
            original_error: "ErrorWithTwoArgs",
            serialized_error: '"An error message"',
            instantiation_error_class: "ArgumentError",
            instantiation_error_message: "wrong number of arguments (given 1, expected 2)",
          },
        )
    end

    it "falls back to StandardError when the client can't initialize the error class when initialize doesn't take a string" do
      allow(Temporal.logger).to receive(:error)

      message = "An error message"
      stack_trace = ["a fake backtrace"]
      failure = Fabricate(
        :api_application_failure,
        message: message,
        backtrace: stack_trace,
        error_class: ErrorThatRaisesInInitialize.to_s,
      )

      e = Temporal::Workflow::Errors.generate_error(failure, converter)
      expect(e).to be_a(StandardError)
      expect(e.message).to eq("ErrorThatRaisesInInitialize: An error message")
      expect(e.backtrace).to eq(stack_trace)
      expect(Temporal.logger)
        .to have_received(:error)
        .with(
          "Could not instantiate original error. Defaulting to StandardError. "\
          "Make sure the worker running your activities is configured with use_error_serialization_v2. "\
          "If so, make sure the original error serialized by searching your logs for 'unserializable_error'. "\
          "If not, you're using legacy serialization, and it's likely that "\
          "your error's initializer takes something other than exactly one positional argument.",
          {
            original_error: "ErrorThatRaisesInInitialize",
            serialized_error: '"An error message"',
            instantiation_error_class: "TypeError",
            instantiation_error_message: "String can't be coerced into Integer",
          },
        )
    end
  end
end
