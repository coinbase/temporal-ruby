require 'cadence/concerns/typed'
require 'fileutils'

class UploadFileActivity < Cadence::Activity
  include Cadence::Concerns::Typed

  task_list 'file-processing'

  input do
    attribute :local_path, Cadence::Types::String
    attribute :remote_path, Cadence::Types::String
  end

  def execute(input)
    file_name = Pathname(input.local_path).basename.to_s
    remote_path = Pathname(input.remote_path).join(file_name)

    FileUtils.mv(input.local_path, remote_path)

    return remote_path.to_s
  end
end
