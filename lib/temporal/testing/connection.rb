# frozen_string_literal: true
require 'temporal/api/testservice/v1/service_services_pb'
require 'temporal/api/testservice/v1/request_response_pb'
require 'temporal/api/testservice/v1//service_pb'
require 'grpc'

module Temporal
  module Testing
    class Connection
      CONNECTION_TIMEOUT_SECONDS = 60
      def initialize(host, port)
        @url = "#{host}:#{port}"
      end

      def lock_time_skipping
        request = Temporal::Api::TestService::V1::LockTimeSkippingRequest.new
        client.lock_time_skipping(request)
      end
      def unlock_time_skipping
        request = Temporal::Api::TestService::V1::UnlockTimeSkippingRequest.new
        client.unlock_time_skipping(request)
      end

      def unlock_time_skipping_with_sleep(duration)
        request = Temporal::Api::TestService::V1::SleepRequest.new(duration:duration)
        client.unlock_time_skipping_with_sleep(request)
      end

      def sleep(duration)
        request = Temporal::Api::TestService::V1::SleepRequest.new(duration:duration)
        client.sleep(request)
      end

      def sleep_until(timestamp)
        request = Temporal::Api::TestService::V1::SleepUntilRequest.new(timestamp:timestamp)
        client.sleep_until(request)
      end
      def client
        return @client if @client

        channel_args = {}
        options = {}

        if options[:keepalive_time_ms]
          channel_args["grpc.keepalive_time_ms"] = options[:keepalive_time_ms]
        end

        if options[:retry_connection] || options[:retry_policy]
          channel_args["grpc.enable_retries"] = 1

          retry_policy = options[:retry_policy] || {
            retryableStatusCodes: ["UNAVAILABLE"],
            maxAttempts: 3,
            initialBackoff: "0.1s",
            backoffMultiplier: 2.0,
            maxBackoff: "0.3s"
          }

          channel_args["grpc.service_config"] = ::JSON.generate(
            methodConfig: [
              {
                name: [
                  {
                    service: "temporal.api.testservice.v1.TestService",
                  }
                ],
                retryPolicy: retry_policy
              }
            ]
          )
        end

        @client = Temporal::Api::TestService::V1::TestService::Stub.new(
          @url,
          :this_channel_is_insecure,
          timeout: CONNECTION_TIMEOUT_SECONDS,
          # interceptors: [ClientNameVersionInterceptor.new],
          channel_args: channel_args
        )
      end

    end
  end
end
