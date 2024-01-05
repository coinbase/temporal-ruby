require 'temporal/errors'

module Temporal
  class Capabilities
    def initialize(config)
      @config = config
      @sdk_metadata = nil
    end

    def sdk_metadata
      set_capabilities if @sdk_metadata.nil?

      @sdk_metadata
    end

    private

    def set_capabilities
      connection = Temporal::Connection.generate(@config.for_connection)
      system_info = connection.get_system_info

      @sdk_metadata = system_info&.capabilities&.sdk_metadata || false

      Temporal.logger.debug(
        "Connected to Temporal server running version #{system_info.server_version}. " \
        "SDK Metadata supported: #{@sdk_metadata}"
      )
    end
  end
end
