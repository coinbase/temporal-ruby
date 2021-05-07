module Temporal
  class Workflow
    class ReplayAwareLogger
      SEVERITIES = %i[debug info warn error fatal unknown].freeze

      attr_writer :replay

      def initialize(main_logger, replay = true)
        @main_logger = main_logger
        @replay = replay
      end

      SEVERITIES.each do |severity|
        define_method severity do |*args|
          return if replay?

          main_logger.public_send(severity, *args)
        end
      end

      def log(severity, *args)
        return if replay?

        main_logger.log(severity, *args)
      end

      private

      attr_reader :main_logger

      def replay?
        @replay
      end
    end
  end
end
