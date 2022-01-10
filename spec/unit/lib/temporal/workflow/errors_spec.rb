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

describe Temporal::Workflow::Errors do
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

      e = Temporal::Workflow::Errors.generate_error(failure)
      expect(e).to be_a(SomeError)
      expect(e.message).to eq(message)
      expect(e.backtrace).to eq(stack_trace)

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

      e = Temporal::Workflow::Errors.generate_error(failure)
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

      e = Temporal::Workflow::Errors.generate_error(failure)
      expect(e).to be_a(StandardError)
      expect(e.message).to eq("ErrorWithTwoArgs: An error message")
      expect(e.backtrace).to eq(stack_trace)
      expect(Temporal.logger)
        .to have_received(:error)
        .with(
          'Could not instantiate original error. Defaulting to StandardError.',
          {
            original_error: "ErrorWithTwoArgs",
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

      e = Temporal::Workflow::Errors.generate_error(failure)
      expect(e).to be_a(StandardError)
      expect(e.message).to eq("ErrorThatRaisesInInitialize: An error message")
      expect(e.backtrace).to eq(stack_trace)
      expect(Temporal.logger)
        .to have_received(:error)
        .with(
          'Could not instantiate original error. Defaulting to StandardError.',
          {
            original_error: "ErrorThatRaisesInInitialize",
            instantiation_error_class: "TypeError",
            instantiation_error_message: "String can't be coerced into Integer",
          },
        )
    end
  end
end
