Fabricator(:api_payload, from: Temporal::Api::Common::V1::Payload) do
  data { |attrs| Temporal::JSON.serialize(attrs[:data] || '') }
end
