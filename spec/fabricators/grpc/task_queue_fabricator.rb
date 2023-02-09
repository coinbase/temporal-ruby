Fabricator(:api_task_queue, from: Temporalio::Api::TaskQueue::V1::TaskQueue) do
  name 'test-task-queue'
end
