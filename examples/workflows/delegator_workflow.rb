# This sample illustrates using a dynamic Activity to delegate to another set of non-activity
# classes.  This is an advanced use case, used, for example, for integrating with an existing framework
# that doesn't know about temporal.
# See Temporal::Worker#register_dynamic_activity for more info.

# An example of another non-Activity class hierarchy.
class MyWorkflowExecutor
  def do_it(_args)
    raise NotImplementedError
  end
end

class PlusExecutor < MyWorkflowExecutor
  def do_it(args)
    args[:a] + args[:b]
  end
end

class TimesExecutor < MyWorkflowExecutor
  def do_it(args)
    args[:a] * args[:b]
  end
end

# Calls into our other class hierarchy.
class DelegatorWorkflow < Temporal::Workflow
  def execute(input)
    executor = Object.const_get(workflow.name).new
    raise ArgumentError, "Unknown workflow: #{executor.class}" unless executor.is_a?(MyWorkflowExecutor)

    {computation: executor.do_it(input)}
  end
end
