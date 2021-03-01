require 'workflows/failing_activities_workflow'

describe FailingActivitiesWorkflow do
  subject { described_class }
  context 'async execution completes' do
    let(:count) { 6 }
    it 'counts are consistent with 2 as the right guess and 0 a terminal failure' do
      expect(FailingActivitiesWorkflow.execute_locally(count))
        .to match(
          finished: a_value == count,
          successes: ['two'],
          terminal_guesses: 1,
          wrong_guesses: 4
        )
    end
  end
end
