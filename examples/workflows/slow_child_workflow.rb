class SlowChildWorkflow < Temporal::Workflow
  def execute(delay)
    if delay.positive?
      workflow.sleep(delay)
    end

    return 'slow child ran'
  end
end
