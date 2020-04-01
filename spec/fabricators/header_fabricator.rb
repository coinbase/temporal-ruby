require 'gen/thrift/cadence_types'
require 'securerandom'

Fabricator(:header, from: CadenceThrift::Header) do
  fields { {} }
end
