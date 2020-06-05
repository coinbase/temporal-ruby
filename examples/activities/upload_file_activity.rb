require 'temporal/concerns/typed'
require 'fileutils'

class UploadFileActivity < Temporal::Activity
  include Temporal::Concerns::Typed

  task_list 'file-processing'

  input do
    attribute :local_path, Temporal::Types::String
    attribute :remote_path, Temporal::Types::String
  end

  def execute(input)
    file_name = Pathname(input.local_path).basename.to_s
    remote_path = Pathname(input.remote_path).join(file_name)

    FileUtils.mv(input.local_path, remote_path)

    return remote_path.to_s
  end
end
