# Simulates Temporal::Connection::Serializer::Failure
Fabricator(:api_application_failure, from: Temporalio::Api::Failure::V1::Failure) do
  transient :error_class, :backtrace
  message { |attrs| attrs[:message] }
  stack_trace { |attrs| attrs[:backtrace].join("\n") }
  application_failure_info do |attrs|
    Temporalio::Api::Failure::V1::ApplicationFailureInfo.new(
      type: attrs[:error_class],
      details: TEST_CONVERTER.to_details_payloads(attrs[:message]),
    )
  end
end
