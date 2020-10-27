require 'temporal/concerns/typed'

class GenerateFileActivity < Temporal::Activity
  include Temporal::Concerns::Typed

  task_queue 'file-processing'

  input Temporal::Types::String

  def execute(input)
    file_name = "#{Time.now.to_i}.txt"
    file_path = Pathname.new(input).join(file_name)

    File.open(file_path, 'w+') { |file| file.puts 'Some important data' }

    return file_path.to_s
  end
end
