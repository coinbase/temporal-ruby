require 'securerandom'

Fabricator(:workflow_metadata, from: :open_struct) do
  run_id { SecureRandom.uuid }
  attempt 1
  headers { {} }
end
