# Can receive signals to its named signal handler. If a signal doesn't match the
# named handler's signature, then it matches the catch-all signal handler
#
class WaitForNamedSignalWorkflow < Temporal::Workflow
  def execute(expected_signal)
    signals_received = {}
    signal_counts = Hash.new { |h,k| h[k] = 0 }

    # catch-all handler
    workflow.on_signal do |signal, input|
      workflow.logger.info("Received signal name as #{signal}, with input #{input.inspect}")
      signals_received['catch-all'] = input
      signal_counts['catch-all'] += 1
    end

    workflow.on_signal('NamedSignal') do |input|
      workflow.logger.info("Received signal name -NamedSignal-, with input #{input.inspect}")
      signals_received['NamedSignal'] = input
      signal_counts['NamedSignal'] += 1
    end

    timeout_timer = workflow.start_timer(1)
    workflow.wait_for_any(timeout_timer)

    { received: signals_received, counts: signal_counts }
  end
end
