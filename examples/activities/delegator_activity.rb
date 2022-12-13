# This sample illustrates using a dynamic Activity to delegate to another set of non-activity
# classes.  This is an advanced use case, used, for example, for integrating with an existing framework
# that doesn't know about temporal.
# See Concerns::Executable#dynamic for more info.

# An example of another class hierarchy.
module MyExecutor
  def call(args)
    context = Temporal::ThreadLocalContext.get
    unless context
      raise "Called #{name}#execute outside of a Workflow context"
    end

    # We want temporal to record 'Plus' or 'Times' as the names of the activites,
    # rather than DelegatorActivity
    context.execute_activity!(
      self,
      args
    )
  end
end

class Plus
  extend MyExecutor

  def do_it(args)
    args[:a] + args[:b]
  end
end

class Times
  extend MyExecutor

  def do_it(args)
    args[:a] * args[:b]
  end
end

# Calls into our other class hierarchy.
class DelegatorActivity < Temporal::Activity

  dynamic

  def execute(input)
    case activity.name
    when 'Plus'
      Plus.new.do_it(input)
    when 'Times'
      Times.new.do_it(input)
    end
  end
end
