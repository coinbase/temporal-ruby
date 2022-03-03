require 'temporal/converter_wrapper'
require 'temporal/configuration'

$converter = Temporal::ConverterWrapper.new(Temporal::Configuration::DEFAULT_CONVERTER)

RSpec.configure do |config|
  config.before(:each) do
    Temporal.configuration.error_handlers.clear
  end
end
