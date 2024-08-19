require 'temporal/converter_wrapper'

# This is a barebones default converter that can be used in tests
# where default conversion behaviour is expected
TEST_CONVERTER = Temporal::ConverterWrapper.new(
  Temporal::Configuration::DEFAULT_CONVERTER,
  Temporal::Configuration::DEFAULT_PAYLOAD_CODEC
).freeze
