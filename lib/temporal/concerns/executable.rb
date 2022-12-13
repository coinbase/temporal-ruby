module Temporal
  module Concerns
    module Executable
      def namespace(*args)
        return @namespace if args.empty?
        @namespace = args.first
      end

      def task_queue(*args)
        return @task_queue if args.empty?
        @task_queue = args.first
      end

      def task_list(*args)
        task_queue(*args)
      end

      def retry_policy(*args)
        return @retry_policy if args.empty?
        @retry_policy = args.first
      end

      def timeouts(*args)
        return @timeouts if args.empty?
        @timeouts = args.first
      end

      def headers(*args)
        return @headers if args.empty?
        @headers = args.first
      end

      # Set this for one special activity or workflow that you want to intercept any unknown Workflows or Activities,
      # perhaps so you can delegate work to other classes.
      # Only one dynamic Activity and one dynamic Workflow may be registered per task queue.
      def dynamic
        @dynamic = true
      end

      def dynamic?
        @dynamic || false
      end
    end
  end
end
