require 'temporal/metadata'
require 'temporal/error_handler'
require 'temporal/errors'
require 'temporal/activity/context'
require 'temporal/json'

module Temporal
  class Activity
    class TaskProcessor
      def initialize(task, namespace, activity_lookup, client, middleware_chain)
        @task = task
        @namespace = namespace
        @metadata = Metadata.generate(Metadata::ACTIVITY_TYPE, task, namespace)
        @task_token = task.task_token
        @activity_name = task.activity_type.name
        @activity_class = activity_lookup.find(activity_name)
        @client = client
        @middleware_chain = middleware_chain
      end

      def process
        start_time = Time.now

        Temporal.metrics.timing('activity_task.queue_time', queue_time_ms, activity: activity_name)

        metadata = Metadata.generate(Metadata::ACTIVITY_TYPE, task, namespace)
        context = Activity::Context.new(client, metadata)

        if !activity_class
          raise ActivityNotRegistered, 'Activity is not registered with this worker'
        end

        context = Activity::Context.new(client, metadata)

        result = middleware_chain.invoke(metadata) do
          activity_class.execute_in_context(context, parse_payload(task.input))
        end

        # Do not complete asynchronous activities, these should be completed manually
        respond_completed(result, context) unless context.async?
      rescue StandardError, ScriptError => error
        Temporal::ErrorHandler.handle(error, metadata: metadata)

        respond_failed(error)
      ensure
        time_diff_ms = ((Time.now - start_time) * 1000).round
        Temporal.metrics.timing('activity_task.latency', time_diff_ms, activity: activity_name)
        Temporal.logger.debug("Activity task processed in #{time_diff_ms}ms (#{context.log_tag})")
      end

      private

      attr_reader :task, :namespace, :task_token, :activity_name, :activity_class, :client, :middleware_chain, :metadata

      def queue_time_ms
        scheduled = task.current_attempt_scheduled_time.to_f
        started = task.started_time.to_f
        ((started - scheduled) * 1_000).round
      end

      def respond_completed(result, context)
        Temporal.logger.info("Activity task completed (#{context.log_tag})")
        client.respond_activity_task_completed(task_token: task_token, result: result)
      rescue StandardError => error
        Temporal.logger.error("Unable to complete Activity #{activity_name}: #{error.inspect}")

        Temporal::ErrorHandler.handle(error, metadata: metadata)
      end

      def respond_failed(error, context)
        Temporal.logger.error("Activity task failed: #{error.inspect} (#{context.log_tag})")
        client.respond_activity_task_failed(task_token: task_token, exception: error)
      rescue StandardError => error
        Temporal.logger.error("Unable to fail Activity #{activity_name}: #{error.inspect}")

        Temporal::ErrorHandler.handle(error, metadata: metadata)
      end

      def parse_payload(payload)
        return if payload.nil? || payload.payloads.empty?

        binary = payload.payloads.first.data
        JSON.deserialize(binary)
      end
    end
  end
end
