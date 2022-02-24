class QueryWorkflow < Temporal::Workflow
  timeouts task: 10

  def execute
    state = "started"
    last_signal_received = nil

    # Demonstrating catch-all query handler.
    workflow.on_query do |query, input|
      case query
      when "last_signal"
        input == "reverse" ? last_signal_received&.reverse : last_signal_received
      else
        nil
        # TODO appropriate error handling?
        # raise StandardError, "Unrecognized query type '#{query}'"
      end
    end

    # Demonstrating targeted query handler. Note that this specific query handler would be invoked
    # instead of the more broad catch-all query handler above.
    workflow.on_query("state") do |input|
      input == "upcase" ? state.upcase : state
    end

    workflow.on_signal { |signal| last_signal_received = signal }

    workflow.wait_for { last_signal_received == "finish" }
    state = "finished"

    {
      last_signal_received: last_signal_received,
      final_state: state
    }
  end
end
