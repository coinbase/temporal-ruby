require 'temporal/execution_options'
require 'temporal/configuration'

describe Temporal::ExecutionOptions do
  let(:config) { Temporal::Configuration.new }

  class TestExecutionOptionsWorkflow < Temporal::Workflow
    namespace 'custom-namespace'
  end

  describe '#initialize' do
    it 'accepts a workflow class' do
      execution_options = Temporal::ExecutionOptions.new(TestExecutionOptionsWorkflow, {}, config.default_execution_options)

      expect(execution_options.name).to eq('TestExecutionOptionsWorkflow')
      expect(execution_options.namespace).to eq('custom-namespace')
    end

    it 'accepts a workflow name as a string' do
      execution_options = Temporal::ExecutionOptions.new('TestExecutionOptionsWorkflow', {}, config.default_execution_options)

      expect(execution_options.name).to eq('TestExecutionOptionsWorkflow')
      expect(execution_options.namespace).to eq('default-namespace')
    end

    it 'accepts a workflow name as a frozen string' do
      execution_options = Temporal::ExecutionOptions.new('TestExecutionOptionsWorkflow'.freeze, {}, config.default_execution_options)

      expect(execution_options.name).to eq('TestExecutionOptionsWorkflow')
      expect(execution_options.namespace).to eq('default-namespace')
    end
  end
end
