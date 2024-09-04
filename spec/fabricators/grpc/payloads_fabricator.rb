Fabricator(:api_payloads, from: Temporalio::Api::Common::V1::Payloads) do
  transient :payloads_array

  payloads do |attrs|
    Google::Protobuf::RepeatedField.new(:message, Temporalio::Api::Common::V1::Payload).tap do |m|
      m.concat(Array(attrs.fetch(:payloads_array, Fabricate(:api_payload))))
    end
  end
end
