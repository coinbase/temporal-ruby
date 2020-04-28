require 'gen/thrift/cadence_types'

Fabricator(:activity_type_thrift, from: CadenceThrift::ActivityType) do
  name 'TestActivity'
end
