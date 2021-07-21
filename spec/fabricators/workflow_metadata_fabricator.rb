require 'securerandom'

Fabricator(:workflow_metadata, from: :open_struct) do
  name 'TestWorkflow'
  workflow_id { "some_workflow_id:#{SecureRandom.uuid}" }
  run_id { SecureRandom.uuid }
  attempt 1
  headers { {} }
  namespace { 'ruby_samples'}
end
