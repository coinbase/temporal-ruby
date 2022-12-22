require 'temporal/execution_options'
require 'temporal/configuration'

describe Temporal::ExecutionOptions do
  subject { described_class.new(object, options, defaults) }
  let(:defaults) { nil }
  let(:options) { { namespace: 'test-namespace', task_queue: 'test-task-queue' } }
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

    context 'when initialized with a String' do
      let(:object) { 'TestWorkflow' }

      it 'is initialized with object as the name' do
        expect(subject.name).to eq(object)
        expect(subject.namespace).to eq(options[:namespace])
        expect(subject.task_queue).to eq(options[:task_queue])
        expect(subject.retry_policy).to be_nil
        expect(subject.timeouts).to eq({})
        expect(subject.headers).to eq({})
      end

      context 'when options include :name' do
        let(:options) do
          { name: 'OtherTestWorkflow', namespace: 'test-namespace', task_queue: 'test-task-queue' }
        end

        it 'is initialized with name from options' do
          expect(subject.name).to eq(options[:name])
          expect(subject.namespace).to eq(options[:namespace])
          expect(subject.task_queue).to eq(options[:task_queue])
          expect(subject.retry_policy).to be_nil
          expect(subject.timeouts).to eq({})
          expect(subject.headers).to eq({})
        end
      end

      context 'with defaults given' do
        let(:options) do
          {
            namespace: 'test-namespace',
            timeouts: { start_to_close: 10 },
            headers: { 'TestHeader' => 'Test' },
            search_attributes: { 'DoubleSearchAttribute' => 3.14 },
          }
        end
        let(:defaults) do
          Temporal::Configuration::Execution.new(
            namespace: 'default-namespace',
            task_queue: 'default-task-queue',
            timeouts: { schedule_to_close: 42 },
            headers: { 'DefaultHeader' => 'Default' },
            search_attributes: { 'DefaultIntSearchAttribute' => 256 },
            workflow_id_reuse_policy: :reject
          )
        end

        it 'is initialized with a mix of options and defaults' do
          expect(subject.name).to eq(object)
          expect(subject.namespace).to eq(options[:namespace])
          expect(subject.task_queue).to eq(defaults.task_queue)
          expect(subject.retry_policy).to be_nil
          expect(subject.timeouts).to eq(schedule_to_close: 42, start_to_close: 10)
          expect(subject.headers).to eq('DefaultHeader' => 'Default', 'TestHeader' => 'Test')
          expect(subject.search_attributes).to eq('DefaultIntSearchAttribute' => 256, 'DoubleSearchAttribute' => 3.14)
          expect(subject.workflow_id_reuse_policy).to eq(:reject)
        end
      end

      context 'with full options' do
        let(:options) do
          {
            name: 'OtherTestWorkflow',
            namespace: 'test-namespace',
            task_queue: 'test-task-queue',
            retry_policy: { interval: 1, backoff: 2, max_attempts: 5 },
            timeouts: { start_to_close: 10 },
            headers: { 'TestHeader' => 'Test' },
            workflow_id_reuse_policy: :reject
          }
        end

        it 'is initialized with full options' do
          expect(subject.name).to eq(options[:name])
          expect(subject.namespace).to eq(options[:namespace])
          expect(subject.task_queue).to eq(options[:task_queue])
          expect(subject.retry_policy).to be_an_instance_of(Temporal::RetryPolicy)
          expect(subject.retry_policy.interval).to eq(options[:retry_policy][:interval])
          expect(subject.retry_policy.backoff).to eq(options[:retry_policy][:backoff])
          expect(subject.retry_policy.max_attempts).to eq(options[:retry_policy][:max_attempts])
          expect(subject.timeouts).to eq(options[:timeouts])
          expect(subject.headers).to eq(options[:headers])
          expect(subject.workflow_id_reuse_policy).to eq(options[:workflow_id_reuse_policy])
        end
      end

      context 'when retry policy options are invalid' do
        let(:options) { { retry_policy: { max_attempts: 10 } } }

        it 'raises' do
          expect { subject }.to raise_error(
            Temporal::RetryPolicy::InvalidRetryPolicy,
            'interval and backoff must be set if max_attempts != 1'
          )
        end
      end
    end

    context 'when initialized with an Executable' do
      class TestWorkflow < Temporal::Workflow
        namespace 'namespace'
        task_queue 'task-queue'
        retry_policy interval: 1, backoff: 2, max_attempts: 5
        timeouts start_to_close: 10
        headers 'HeaderA' => 'TestA', 'HeaderB' => 'TestB'
        workflow_id_reuse_policy :reject
      end

      let(:object) { TestWorkflow }
      let(:options) { {} }

      it 'is initialized with executable values' do
        expect(subject.name).to eq(object.name)
        expect(subject.namespace).to eq('namespace')
        expect(subject.task_queue).to eq('task-queue')
        expect(subject.retry_policy).to be_an_instance_of(Temporal::RetryPolicy)
        expect(subject.retry_policy.interval).to eq(1)
        expect(subject.retry_policy.backoff).to eq(2)
        expect(subject.retry_policy.max_attempts).to eq(5)
        expect(subject.timeouts).to eq(start_to_close: 10)
        expect(subject.headers).to eq('HeaderA' => 'TestA', 'HeaderB' => 'TestB')
        expect(subject.workflow_id_reuse_policy).to eq(:reject)
      end

      context 'when options are present' do
        let(:options) do
          {
            name: 'OtherTestWorkflow',
            task_queue: 'test-task-queue',
            retry_policy: { interval: 2, max_attempts: 10 },
            timeouts: { schedule_to_close: 20 },
            headers: { 'TestHeader' => 'Value', 'HeaderB' => 'ValueB' },
            workflow_id_reuse_policy: :allow_failed
          }
        end

        it 'is initialized with a mix of options and executable values' do
          expect(subject.name).to eq(options[:name])
          expect(subject.namespace).to eq('namespace')
          expect(subject.task_queue).to eq(options[:task_queue])
          expect(subject.retry_policy).to be_an_instance_of(Temporal::RetryPolicy)
          expect(subject.retry_policy.interval).to eq(2)
          expect(subject.retry_policy.backoff).to eq(2)
          expect(subject.retry_policy.max_attempts).to eq(10)
          expect(subject.timeouts).to eq(schedule_to_close: 20, start_to_close: 10)
          expect(subject.headers).to eq(
            'TestHeader' => 'Value',
            'HeaderA' => 'TestA',
            'HeaderB' => 'ValueB' # overriden by options
          )
          expect(subject.workflow_id_reuse_policy).to eq(:allow_failed)
        end
      end

      context 'with defaults given' do
        let(:options) do
          {
            namespace: 'test-namespace',
            timeouts: { schedule_to_start: 10 },
            headers: { 'TestHeader' => 'Test' }
          }
        end
        let(:defaults) do
          Temporal::Configuration::Execution.new(
            namespace: 'default-namespace',
            task_queue: 'default-task-queue',
            timeouts: { schedule_to_close: 42 },
            headers: { 'DefaultHeader' => 'Default', 'HeaderA' => 'DefaultA' },
            search_attributes: {},
            workflow_id_reuse_policy: :allow_failed
          )
        end

        it 'is initialized with a mix of executable values, options and defaults' do
          expect(subject.name).to eq(object.name)
          expect(subject.namespace).to eq(options[:namespace])
          expect(subject.task_queue).to eq('task-queue')
          expect(subject.retry_policy).to be_an_instance_of(Temporal::RetryPolicy)
          expect(subject.retry_policy.interval).to eq(1)
          expect(subject.retry_policy.backoff).to eq(2)
          expect(subject.retry_policy.max_attempts).to eq(5)
          expect(subject.timeouts).to eq(schedule_to_close: 42, start_to_close: 10, schedule_to_start: 10)
          expect(subject.headers).to eq(
            'TestHeader' => 'Test',
            'HeaderA' => 'TestA',
            'HeaderB' => 'TestB', # not overriden by defaults
            'DefaultHeader' => 'Default'
          )
          expect(subject.workflow_id_reuse_policy).to eq(:reject)
        end
      end

      context 'when retry policy options are invalid' do
        let(:options) { { retry_policy: { interval: 1.5 } } }

        it 'raises' do
          expect { subject }.to raise_error(
            Temporal::RetryPolicy::InvalidRetryPolicy,
            'All intervals must be specified in whole seconds'
          )
        end
      end
    end
  end
end
