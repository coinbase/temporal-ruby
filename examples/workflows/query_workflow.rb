class QueryWorkflow < Temporal::Workflow
  attr_reader :state, :signal_count, :last_signal_received

  def execute
    @state = "started"
    @signal_count = 0
    @last_signal_received = nil

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
