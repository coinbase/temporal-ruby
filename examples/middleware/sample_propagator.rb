class SamplePropagator
  def inject!(headers)
    headers['test-header'] = 'test'
  end

  def call(metadata)
    Temporal.logger.info("Got headers!", headers: metadata.headers.to_h)
    yield
  end
end