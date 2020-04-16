require 'base64'

module Cadence
  class Activity
    class AsyncToken
      SEPARATOR = '|'.freeze

      attr_reader :domain, :activity_id, :workflow_id, :run_id

      def self.encode(domain, activity_id, workflow_id, run_id)
        new(domain, activity_id, workflow_id, run_id).to_s
      end

      def self.decode(token)
        string = Base64.urlsafe_decode64(token)
        domain, activity_id, workflow_id, run_id = string.split(SEPARATOR)

        new(domain, activity_id, workflow_id, run_id)
      end

      def initialize(domain, activity_id, workflow_id, run_id)
        @domain = domain
        @activity_id = activity_id
        @workflow_id = workflow_id
        @run_id = run_id
      end

      def to_s
        parts = [domain, activity_id, workflow_id, run_id]
        Base64.urlsafe_encode64(parts.join(SEPARATOR)).freeze
      end
    end
  end
end
