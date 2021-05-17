class LoggingMiddleware
  def initialize(app_name)
    @app_name = app_name
  end

  def call(metadata)
    entity_name = name_from(metadata)
    entity_type = type_from(metadata)
    Temporal.logger.info("[#{app_name}]: Started", metadata: metadata.to_h)

    yield

    Temporal.logger.info("[#{app_name}]: Finished", metadata: metadata.to_h)
  rescue StandardError
    Temporal.logger.error("[#{app_name}]: Error", metadata: metadata.to_h)

    raise
  end

  private

  attr_reader :app_name

  def type_from(metadata)
    if metadata.activity?
      'activity'
    elsif metadata.workflow_task?
      'task'
    end
  end

  def name_from(metadata)
    if metadata.activity?
      metadata.name
    elsif metadata.workflow_task?
      metadata.workflow_name
    end
  end
end
