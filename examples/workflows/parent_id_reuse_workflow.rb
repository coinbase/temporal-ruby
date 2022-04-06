require 'workflows/hello_world_workflow'
require 'workflows/failing_workflow'

class ParentIdReuseWorkflow < Temporal::Workflow
  def execute(workflow_id_1, workflow_id_2, fail_first, reuse_policy)
    execute_child(workflow_id_1, fail_first, reuse_policy)
    execute_child(workflow_id_2, false, reuse_policy)
  end

  def execute_child(workflow_id, fail, reuse_policy)
    options = {
      workflow_id: workflow_id,
      workflow_id_reuse_policy: reuse_policy
    }

    future = fail ? FailingWorkflow.execute(options: options) : HelloWorldWorkflow.execute(options: options)
    future.wait
    raise future.get if future.failed? && !fail
  end
end
