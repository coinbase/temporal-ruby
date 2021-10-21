require 'securerandom'

Fabricator(:workflow_metadata, from: :open_struct) do
  namespace 'test-namespace'
  id { SecureRandom.uuid }
  name 'TestWorkflow'
  run_id { SecureRandom.uuid }
  attempt 1
  headers { {} }
end
