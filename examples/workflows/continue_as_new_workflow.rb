require 'activities/hello_world_activity'

# Demonstrates how to use history_size to determine when to continue as new
class ContinueAsNewWorkflow < Temporal::Workflow
  def execute(hello_count, bytes_max, run = 1)
    while hello_count.positive? && workflow.history_size.bytes < bytes_max
      HelloWorldActivity.execute!("Alice Long#{'long' * 100}name")
      hello_count -= 1
    end

    workflow.logger.info("Workflow history size: #{workflow.history_size}, remaining hellos: #{hello_count}")

    return workflow.continue_as_new(hello_count, bytes_max, run + 1) if hello_count.positive?

    {
      runs: run
    }
  end
end
