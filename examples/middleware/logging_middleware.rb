class LoggingMiddleware
  def initialize(scope)
    @scope = scope
  end

  def call(metadata)
    Cadence.logger.info("#{scope}: Started")

    yield

    Cadence.logger.info("#{scope}: Finished")
  rescue StandardError => e
    Cadence.logger.error("#{scope}: Error")

    raise
  end

  private

  attr_reader :scope
end
