require 'workflows/wait_for_named_signal_workflow'

describe WaitForNamedSignalWorkflow, :integration do
  let(:receiver_workflow_id) { SecureRandom.uuid }

  context 'when the signal is named' do
    let(:arg1) { "arg1" }
    let(:arg2) { 7890.1234 }

    context 'and the workflow has a named signal handler matching the signal name' do
      let(:signal_name) { "NamedSignal" }

      it 'receives the signal in its named handler' do
        _, run_id = run_workflow(WaitForNamedSignalWorkflow, signal_name, options: { workflow_id: receiver_workflow_id})

        Temporal.signal_workflow(WaitForNamedSignalWorkflow, signal_name, receiver_workflow_id, run_id, [arg1, arg2])

        result = Temporal.await_workflow_result(
          WaitForNamedSignalWorkflow,
          workflow_id: receiver_workflow_id,
          run_id: run_id,
        )

        expect(result[:received]).to include({signal_name => [arg1, arg2]})
        expect(result[:counts]).to include({signal_name => 1})
        expect(result).to eq(
          {
            received: {
              signal_name => [arg1, arg2],
              'catch-all' => [arg1, arg2]
            },
            counts: {
              signal_name => 1,
              'catch-all' => 1
            }
          }
        )

      end

      it 'receives the signal in its catch-all signal handler' do
        _, run_id = run_workflow(WaitForNamedSignalWorkflow, signal_name, options: { workflow_id: receiver_workflow_id})

        Temporal.signal_workflow(WaitForNamedSignalWorkflow, signal_name, receiver_workflow_id, run_id, [arg1, arg2])

        result = Temporal.await_workflow_result(
          WaitForNamedSignalWorkflow,
          workflow_id: receiver_workflow_id,
          run_id: run_id,
        )

        expect(result[:received]).to include({"catch-all" => [arg1, arg2]})
        expect(result[:counts]).to include({"catch-all" => 1})
      end
    end

    context 'and the workflow does NOT have a named signal handler matching the signal name' do
      let(:signal_name) { 'doesNOTmatchAsignalHandler' }

      it 'receives the signal in its catch-all signal handler' do
        _, run_id = run_workflow(WaitForNamedSignalWorkflow, signal_name, options: { workflow_id: receiver_workflow_id})

        Temporal.signal_workflow(WaitForNamedSignalWorkflow, signal_name, receiver_workflow_id, run_id, [arg1, arg2])

        result = Temporal.await_workflow_result(
          WaitForNamedSignalWorkflow,
          workflow_id: receiver_workflow_id,
          run_id: run_id,
        )

        expect(result).to eq(
          {
            received: {
              'catch-all' => [arg1, arg2]
            },
            counts: {
              'catch-all' => 1
            }
          }
        )
      end
    end
  end
end
