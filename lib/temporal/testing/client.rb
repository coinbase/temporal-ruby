# frozen_string_literal: true
module Temporal
  module Testing
    # TestingClient expects the java `temporal-test-server` to be running and to have been
    # enabled with timeskipping with
    # `./temporal-test-server {port} --enable-time-skipping`
    class Client < Temporal::Client
      def initialize(config = {})
        super(config)
        @timeskipping_connection = Connection.new(config.host, config.port)
      end

      def sleep(duration)
        @timeskipping_connection.unlock_time_skipping_with_sleep(duration)
      end

      def await_workflow_result(workflow, workflow_id:, run_id: nil, timeout: nil, namespace: nil)
        begin
          # WorkflowTaskTimeout seems to happen with this SDK so sleep as workaround
          sleep(0.25)
          @timeskipping_connection.unlock_time_skipping
          super
        ensure
          @timeskipping_connection.lock_time_skipping
        end
      end
    end
  end

end