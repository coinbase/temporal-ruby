require 'gen/thrift/temporal_types'
require 'securerandom'

Fabricator(:header_thrift, from: TemporalThrift::Header) do
  fields { {} }
end
