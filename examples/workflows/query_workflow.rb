class QueryWorkflow < Temporal::Workflow
  attr_reader :state, :signal_count, :last_signal_received

  def execute
    @state = "started"
    @signal_count = 0
    @last_signal_received = nil

    # Demonstrating catch-all query handler.
    workflow.on_query do |query, *args|
      case query
      when "last_signal"
        apply_transforms(last_signal_received, args)
      else
        nil
        # TODO appropriate error handling?
        # raise StandardError, "Unrecognized query type '#{query}'"
      end
    end

    # Demonstrating targeted query handlers. Note that these specific query handlers
    # are invoked instead of the more broad catch-all query handler above.
    workflow.on_query("state") { |*args| apply_transforms(state, args) }
    workflow.on_query("signal_count") { signal_count }

    workflow.on_signal do |signal|
      @signal_count += 1
      @last_signal_received = signal
    end

    workflow.wait_for { last_signal_received == "finish" }
    @state = "finished"

    {
      signal_count: signal_count,
      last_signal_received: last_signal_received,
      final_state: state
    }
  end

  private

  def apply_transforms(value, transforms)
    return value if value.nil? || transforms.empty?
    transforms.inject(value) do |memo, input|
      next memo unless memo.respond_to?(input)
      memo.public_send(input)
    end
  end
end
