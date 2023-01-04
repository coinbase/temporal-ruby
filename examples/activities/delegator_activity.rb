# This sample illustrates using a dynamic Activity to delegate to another set of non-activity
# classes.  This is an advanced use case, used, for example, for integrating with an existing framework
# that doesn't know about temporal.
# See Temporal::Worker#register_dynamic_activity for more info.

# An example of another non-Activity class hierarchy.
class MyExecutor
  def do_it(_args)
    raise NotImplementedError
  end
end

class Plus < MyExecutor
  def do_it(args)
    args[:a] + args[:b]
  end
end

class Times < MyExecutor
  def do_it(args)
    args[:a] * args[:b]
  end
end

# Calls into our other class hierarchy.
class DelegatorActivity < Temporal::Activity
  def execute(input)
    executor = Object.const_get(activity.name).new
    raise ArgumentError, "Unknown activity: #{executor.class}" unless executor.is_a?(MyExecutor)

    executor.do_it(input)
  end
end
