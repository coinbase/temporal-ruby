require 'temporal/execution_options'

describe Temporal::ExecutionOptions do
  class TestExecutionOptionsWorkflow < Temporal::Workflow
    namespace 'custom-namespace'
  end

  describe '#initialize' do
    it 'accepts a workflow class' do
      execution_options = Temporal::ExecutionOptions.new(TestExecutionOptionsWorkflow)

      expect(execution_options.name).to eq('TestExecutionOptionsWorkflow')
      expect(execution_options.namespace).to eq('custom-namespace')
    end

    it 'accepts a workflow name as a string' do
      execution_options = Temporal::ExecutionOptions.new('TestExecutionOptionsWorkflow')

      expect(execution_options.name).to eq('TestExecutionOptionsWorkflow')
      expect(execution_options.namespace).to eq('default-namespace')
    end

    it 'accepts a workflow name as a frozen string' do
      execution_options = Temporal::ExecutionOptions.new('TestExecutionOptionsWorkflow'.freeze)

      expect(execution_options.name).to eq('TestExecutionOptionsWorkflow')
      expect(execution_options.namespace).to eq('default-namespace')
    end
  end
end
