require 'temporal/metadata'
require 'temporal/activity/context'
require 'temporal/json'

module Temporal
  class Activity
    class TaskProcessor
      def initialize(task, domain, activity_lookup, client, middleware_chain)
        @task = task
        @domain = domain
        @task_token = task.task_token
        @activity_name = task.activity_type.name
        @activity_class = activity_lookup.find(activity_name)
        @client = client
        @middleware_chain = middleware_chain
      end

      def process
        start_time = Time.now

        Temporal.logger.info("Processing activity task for #{activity_name}")
        Temporal.metrics.timing('activity_task.queue_time', queue_time_ms, activity: activity_name)

        if !activity_class
          respond_failed('ActivityNotRegistered', 'Activity is not registered with this worker')
          return
        end

        metadata = Metadata.generate(Metadata::ACTIVITY_TYPE, task, domain)
        context = Activity::Context.new(client, metadata)

        result = middleware_chain.invoke(metadata) do
          activity_class.execute_in_context(context, JSON.deserialize(task.input.payloads.first.data))
        end

        # Do not complete asynchronous activities, these should be completed manually
        respond_completed(result) unless context.async?
      rescue StandardError, ScriptError => error
        respond_failed(error.class.name, error.message)
      ensure
        time_diff_ms = ((Time.now - start_time) * 1000).round
        Temporal.metrics.timing('activity_task.latency', time_diff_ms, activity: activity_name)
        Temporal.logger.debug("Activity task processed in #{time_diff_ms}ms")
      end

      private

      attr_reader :task, :domain, :task_token, :activity_name, :activity_class, :client, :middleware_chain

      def queue_time_ms
        scheduled = task.current_attempt_scheduled_time.to_f
        started = task.started_timestamp.to_f
        ((started - scheduled) * 1_000).round
      end

      def respond_completed(result)
        Temporal.logger.info("Activity #{activity_name} completed")
        client.respond_activity_task_completed(task_token: task_token, result: result)
      rescue StandardError => error
        Temporal.logger.error("Unable to complete Activity #{activity_name}: #{error.inspect}")
      end

      def respond_failed(reason, details)
        Temporal.logger.error("Activity #{activity_name} failed with: #{reason}")
        client.respond_activity_task_failed(task_token: task_token, reason: reason, details: details)
      rescue StandardError => error
        Temporal.logger.error("Unable to fail Activity #{activity_name}: #{error.inspect}")
      end
    end
  end
end
