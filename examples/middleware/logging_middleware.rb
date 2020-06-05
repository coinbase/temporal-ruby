class LoggingMiddleware
  def initialize(app_name)
    @app_name = app_name
  end

  def call(metadata)
    entity_name = name_from(metadata)
    Temporal.logger.info("[#{app_name}]: Started #{entity_name}")

    yield

    Temporal.logger.info("[#{app_name}]: Finished #{entity_name}")
  rescue StandardError => e
    Temporal.logger.error("[#{app_name}]: Error #{entity_name}")

    raise
  end

  private

  attr_reader :app_name

  def name_from(metadata)
    if metadata.activity?
      metadata.name
    elsif metadata.decision?
      metadata.workflow_name
    end
  end
end
