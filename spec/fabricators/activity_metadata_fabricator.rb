require 'securerandom'

Fabricator(:activity_metadata, from: :open_struct) do
  namespace 'test-namespace'
  id { sequence(:activity_id) }
  name 'TestActivity'
  task_token { SecureRandom.uuid }
  attempt 1
  workflow_run_id { SecureRandom.uuid }
  workflow_id { SecureRandom.uuid }
  workflow_name 'TestWorkflow'
  headers { {} }
  heartbeat_details nil
end
