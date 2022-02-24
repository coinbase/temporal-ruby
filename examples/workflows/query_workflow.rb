class QueryWorkflow < Temporal::Workflow
  timeouts task: 10

  attr_reader :last_signal_received, :state

  def execute
    @state = "started"
    @last_signal_received = nil

    # Demonstrating catch-all query handler.
    workflow.on_query nil, &method(:query_catch)

    # Demonstrating targeted query handler. Note that this specific query handler would be invoked
    # for "state" instead of the more broad catch-all query handler above.
    workflow.on_query "state" do |*args|
      apply_transforms(state, args)
    end

    workflow.on_signal { |signal| @last_signal_received = signal }

    workflow.wait_for { last_signal_received == "finish" }
    @state = "finished"

    {
      last_signal_received: last_signal_received,
      final_state: state
    }
  end

  private

  def query_catch(query, *args)
    case query
    when "last_signal"
      return last_signal_received if last_signal_received.nil? || args.empty?
      apply_transforms(last_signal_received, args)
    else
      nil
      # TODO appropriate error handling?
      # raise StandardError, "Unrecognized query type '#{query}'"
    end
  end

  def apply_transforms(value, transforms)
    return value if value.nil? || transforms.empty?
    transforms.inject(value) do |memo, input|
      next memo unless memo.respond_to?(input)
      memo.public_send(input)
    end
  end
end
