class AsyncActivity < Temporal::Activity
  timeouts start_to_close: 120

  def execute
    # expose async token via a global var for specs
    # TODO: A much better solution would be to implement a DescribeWorkflowExecution
    #       call and return the list of pending activities and their async tokens
    $async_token = activity.async_token

    logger.warn "run `bin/activity complete #{activity.async_token}` to complete activity"

    activity.async
  end
end
