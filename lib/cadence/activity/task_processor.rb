require 'cadence/client'
require 'cadence/activity/metadata'
require 'cadence/activity/context'

module Cadence
  class Activity
    class TaskProcessor
      def initialize(task, activity_lookup)
        @task = task
        @task_token = task.taskToken
        @activity_name = task.activityType.name
        @activity_class = activity_lookup.find(activity_name)
        @activity_lookup = activity_lookup
      end

      def process
        Cadence.logger.info("Processing activity task for #{activity_name}")

        if !activity_class
          respond_failed('ActivityNotRegistered', 'Activity is not registered with this worker')
          return
        end

        metadata = Activity::Metadata.from_task(task)
        context = Activity::Context.new(client, metadata)
        result = activity_class.execute_in_context(context, parse_input(task.input))

        respond_completed(result)
      rescue StandardError => error
        respond_failed(error.class.name, error.message)
      end

      private

      attr_reader :task, :task_token, :activity_name, :activity_class, :activity_lookup

      def client
        @client ||= Cadence::Client.generate
      end

      def parse_input(input)
        input.to_s.empty? ? nil : Oj.load(input)
      end

      def respond_completed(result)
        Cadence.logger.info("Activity #{activity_class} completed")
        client.respond_activity_task_completed(task_token: task_token, result: result)
      rescue StandardError => error
        Cadence.logger.error("Unable to complete Activity #{activity_class}: #{error.inspect}")
      end

      def respond_failed(reason, details)
        Cadence.logger.error("Activity #{activity_class} failed with: #{reason}")
        client.respond_activity_task_failed(task_token: task_token, reason: reason, details: details)
      rescue StandardError => error
        Cadence.logger.error("Unable to fail Activity #{activity_class}: #{error.inspect}")
      end
    end
  end
end
