require 'temporal/workflow/stack_trace_tracker'

describe Temporal::Workflow::StackTraceTracker do
  subject { described_class.new }
  describe '#to_s' do
    def record_function
      subject.record
    end

    def record_and_clear_function
      subject.record
      subject.clear
    end

    def record_two_function
      subject.record

      Fiber.new do
        subject.record
      end.resume
    end

    it 'starts empty' do
      expect(subject.to_s).to eq("Fiber count: 0\n")
    end

    it 'one fiber' do
      record_function
      stack_trace = subject.to_s
      expect(stack_trace).to start_with("Fiber count: 1\n\n")

      first_stack_line = stack_trace.split("\n")[2]
      expect(first_stack_line).to include("record_function")
    end

    it 'one fiber cleared' do
      record_and_clear_function
      stack_trace = subject.to_s
      expect(stack_trace).to start_with("Fiber count: 0\n")
    end

    it 'two fibers' do
      record_two_function
      output = subject.to_s
      expect(output).to start_with("Fiber count: 2\n\n")

      stack_traces = output.split("\n\n")

      first_stack = stack_traces[1]
      expect(first_stack).to include("record_two_function")

      second_stack = stack_traces[2]
      expect(second_stack).to include("block in record_two_function")
    end
  end
end