require 'securerandom'

Fabricator(:workflow_task_metadata, from: :open_struct) do
  namespace 'test-namespace'
  id { sequence(:workflow_task_id) }
  task_token { SecureRandom.uuid }
  attempt 1
  workflow_run_id { SecureRandom.uuid }
  workflow_id { SecureRandom.uuid }
  workflow_name 'TestWorkflow'
end
