require 'securerandom'

Fabricator(:workflow_metadata, from: :open_struct) do
  namespace 'test-namespace'
  id { SecureRandom.uuid }
  name 'TestWorkflow'
  run_id { SecureRandom.uuid }
  attempt 1
  task_queue { Fabricate(:api_task_queue) }
  run_started_at { Time.now }
  memo { {} }
  headers { {} }
end
