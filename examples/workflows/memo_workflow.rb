class MemoWorkflow < Temporal::Workflow
  def execute(name = 'Alice')
    return workflow.memo['foo']
  end
end
