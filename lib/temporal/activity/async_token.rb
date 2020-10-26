require 'base64'

module Temporal
  class Activity
    class AsyncToken
      SEPARATOR = '|'.freeze

      attr_reader :namespace, :activity_id, :workflow_id, :run_id

      def self.encode(namespace, activity_id, workflow_id, run_id)
        new(namespace, activity_id, workflow_id, run_id).to_s
      end

      def self.decode(token)
        string = Base64.urlsafe_decode64(token)
        namespace, activity_id, workflow_id, run_id = string.split(SEPARATOR)

        new(namespace, activity_id, workflow_id, run_id)
      end

      def initialize(namespace, activity_id, workflow_id, run_id)
        @namespace = namespace
        @activity_id = activity_id
        @workflow_id = workflow_id
        @run_id = run_id
      end

      def to_s
        parts = [namespace, activity_id, workflow_id, run_id]
        Base64.urlsafe_encode64(parts.join(SEPARATOR)).freeze
      end
    end
  end
end
