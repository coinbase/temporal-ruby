require 'activities/hello_world_activity'

class CheckWorkflow < Temporal::Workflow
  def execute
    future_1 = HelloWorldActivity.execute('alpha')
    future_2 = HelloWorldActivity.execute('beta')
    future_3 = HelloWorldActivity.execute('gamma')

    logger.info(' => Future 1 is ready!') if future_1.ready?

    future_1.done do |result|
      logger.info("X: future_1 completed", { time: workflow.now.strftime('%H:%M:%S.%L') })
    end

    result = future_2.get
    logger.info("X: future_2 completed", { time: workflow.now.strftime('%H:%M:%S.%L') })

    logger.info(' => Future 3 is ready!') if future_3.ready?
    logger.info(' => Future 2 is ready!') if future_2.ready?

    future_3.done do |result|
      logger.info("X: future_3 completed", { time: workflow.now.strftime('%H:%M:%S.%L') })
    end

    workflow.wait_for_all(future_1, future_2, future_3)
  end
end
