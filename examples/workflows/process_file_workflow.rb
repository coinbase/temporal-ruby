require 'activities/generate_file_activity'
require 'activities/upload_file_activity'
require 'activities/process_file_activity'

class ProcessFileWorkflow < Temporal::Workflow
  task_queue 'file-processing'

  def execute
    local_directory = File.expand_path('~/Development/tmp/temporal/local/').to_s
    remote_directory = File.expand_path('~/Development/tmp/temporal/remote/').to_s

    file_path = GenerateFileActivity.execute!(local_directory)
    remote_path = UploadFileActivity.execute!(local_path: file_path, remote_path: remote_directory)
    result = ProcessFileActivity.execute(remote_path)

    result.get

    raise 'Unable to upload a file' unless result.ready?
  end
end
