require 'gen/thrift/cadence_types'
require 'securerandom'

Fabricator(:header_thrift, from: CadenceThrift::Header) do
  fields { {} }
end
