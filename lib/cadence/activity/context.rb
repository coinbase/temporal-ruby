# This context class is available in the activity implementation
# and provides context and methods for interacting with Cadence
#
module Cadence
  class Activity
    class Context
      def initialize(client, task_token)
        @client = client
        @task_token = task_token
      end

      def heartbeat(details = nil)
        Cadence.logger.debug('Activity heartbeat')
        client.record_activity_task_heartbeat(task_token: task_token, details: details)
      end

      def logger
        Cadence.logger
      end

      private

      attr_reader :client, :task_token
    end
  end
end
