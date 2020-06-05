require 'gen/thrift/temporal_types'

Fabricator(:activity_type_thrift, from: TemporalThrift::ActivityType) do
  name 'TestActivity'
end
