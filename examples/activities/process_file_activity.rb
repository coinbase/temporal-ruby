require 'cadence/concerns/typed'

class ProcessFileActivity < Cadence::Activity
  include Cadence::Concerns::Typed

  task_list 'file-processing'

  input Cadence::Types::String

  def execute(input)
    file_contents = File.read(input)

    logger.info("Processing file: #{input}")
    logger.info("File contents: #{file_contents}")

    raise 'unknown file'
  end
end
