# This context class is available in the activity implementation
# and provides context and methods for interacting with Temporal
#
require 'temporal/uuid'
require 'temporal/activity/async_token'

module Temporal
  class Activity
    class Context
      attr_reader :metadata

      def initialize(connection, metadata, activity_name)
        @connection = connection
        @metadata = metadata
        @async = false
        @name = activity_name
      end

      def async
        @async = true
      end

      def async?
        @async
      end

      def async_token
        AsyncToken.encode(
          metadata.namespace,
          metadata.id,
          metadata.workflow_id,
          metadata.workflow_run_id
        )
      end

      def heartbeat(details = nil)
        logger.debug('Activity heartbeat', metadata.to_h)
        connection.record_activity_task_heartbeat(namespace: metadata.namespace, task_token: task_token, details: details)
      end

      def heartbeat_details
        metadata.heartbeat_details
      end

      def logger
        Temporal.logger
      end

      def run_idem
        UUID.v5(metadata.workflow_run_id.to_s, metadata.id.to_s)
      end
      alias idem run_idem

      def workflow_idem
        UUID.v5(metadata.workflow_id.to_s, metadata.id.to_s)
      end

      def headers
        metadata.headers
      end

      attr_reader :name

      private

      attr_reader :connection

      def task_token
        metadata.task_token
      end
    end
  end
end
