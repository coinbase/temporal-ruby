RSpec.configure do |config|
  config.before(:each) do
    Temporal.configuration.error_handlers.clear
  end
end