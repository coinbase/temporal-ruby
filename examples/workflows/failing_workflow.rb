class FailingWorkflow < Temporal::Workflow
  class SomeError < StandardError; end
  def execute
    raise SomeError, 'Whoops'
  end
end
