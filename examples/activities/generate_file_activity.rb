require 'cadence/concerns/typed'

class GenerateFileActivity < Cadence::Activity
  include Cadence::Concerns::Typed

  task_list 'file-processing'

  input Cadence::Types::String

  def execute(input)
    file_name = "#{Time.now.to_i}.txt"
    file_path = Pathname.new(input).join(file_name)

    File.open(file_path, 'w+') { |file| file.puts 'Some important data' }

    return file_path.to_s
  end
end
