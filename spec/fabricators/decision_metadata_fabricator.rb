require 'securerandom'

Fabricator(:decision_metadata, from: :open_struct) do
  domain 'test-domain'
  id { sequence(:decision_id) }
  task_token { SecureRandom.uuid }
  attempt 1
  workflow_run_id { SecureRandom.uuid }
  workflow_id { SecureRandom.uuid }
  workflow_name 'TestWorkflow'
end
