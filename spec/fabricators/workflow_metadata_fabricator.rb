require 'securerandom'

Fabricator(:workflow_metadata, from: :open_struct) do
  namespace 'test-namespace'
  id { SecureRandom.uuid }
  name 'TestWorkflow'
  run_id { SecureRandom.uuid }
  parent_id { nil }
  parent_run_id { nil }
  attempt 1
  task_queue { Fabricate(:api_task_queue) }
  run_started_at { Time.now }
  memo { {} }
  headers { {} }
  namespace { 'ruby_samples' }
  task_queue { Fabricate(:api_task_queue) }
  memo { {} }
  run_started_at { Time.now }
end
