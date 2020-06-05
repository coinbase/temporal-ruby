require 'temporal/concerns/typed'

class ProcessFileActivity < Temporal::Activity
  include Temporal::Concerns::Typed

  task_list 'file-processing'

  input Temporal::Types::String

  def execute(input)
    file_contents = File.read(input)

    logger.info("Processing file: #{input}")
    logger.info("File contents: #{file_contents}")

    raise 'unknown file'
  end
end
