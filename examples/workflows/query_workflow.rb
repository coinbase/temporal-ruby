class QueryWorkflow < Temporal::Workflow
  def execute
    state = "waiting for cancel"
    last_signal_received = nil
    workflow.on_query("state") do |input|
      input == "upcase" ? state.upcase : state
    end

    workflow.on_signal do |signal|
      last_signal_received = signal
    end

    workflow.wait_for do
      last_signal_received == "cancel"
    end
    state = "cancelled"

    {
      final_state: state
    }
  end
end
