require 'cadence/retry_policy'

module Cadence
  module Concerns
    module Executable
      def domain(*args)
        return @domain if args.empty?
        @domain = args.first
      end

      def task_list(*args)
        return @task_list if args.empty?
        @task_list = args.first
      end

      def retry_policy(*args)
        return @retry_policy if args.empty?
        @retry_policy = Cadence::RetryPolicy.new(args.first)
        @retry_policy.validate!
      end

      def timeouts(*args)
        return @timeouts if args.empty?
        @timeouts = args.first
      end

      def headers(*args)
        return @headers if args.empty?
        @headers = args.first
      end
    end
  end
end
