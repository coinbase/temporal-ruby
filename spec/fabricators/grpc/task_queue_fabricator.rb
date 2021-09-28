Fabricator(:api_task_queue, from: Temporal::Api::TaskQueue::V1::TaskQueue) do
  name 'test-task-queue'
end
