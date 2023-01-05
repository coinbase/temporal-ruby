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

      def workflow_id_reuse_policy(*args)
        return @workflow_id_reuse_policy if args.empty?
        @workflow_id_reuse_policy = args.first
      end
    end
  end
end
