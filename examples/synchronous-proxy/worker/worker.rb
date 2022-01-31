require_relative "../configuration"
require_relative "../workflows"
require_relative "../activities"
require 'temporal/worker'

worker = Temporal::Worker.new
worker.register_workflow(SynchronousProxy::OrderWorkflow)
worker.register_workflow(SynchronousProxy::UpdateOrderWorkflow)
worker.register_workflow(SynchronousProxy::ShippingWorkflow)
worker.register_activity(SynchronousProxy::RegisterEmailActivity)
worker.register_activity(SynchronousProxy::ValidateSizeActivity)
worker.register_activity(SynchronousProxy::ValidateColorActivity)
worker.register_activity(SynchronousProxy::ScheduleDeliveryActivity)
worker.register_activity(SynchronousProxy::SendDeliveryEmailActivity)
worker.start
