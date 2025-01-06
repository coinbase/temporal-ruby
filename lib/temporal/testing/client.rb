# frozen_string_literal: true
module Temporal
  module Testing
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