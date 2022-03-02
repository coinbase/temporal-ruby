require_relative "proxy/communications"
require_relative "activities"

module SynchronousProxy
  RegisterStage = "register".freeze
  SizeStage = "size".freeze
  ColorStage = "color".freeze
  ShippingStage = "shipping".freeze

  TShirtSizes = ["small", "medium", "large"]
  TShirtColors = ["red", "blue", "black"]

  OrderStatus = Struct.new(:order_id, :stage, keyword_init: true)
  TShirtOrder = Struct.new(:email, :size, :color) do
    def to_s
      "size: #{size}, color: #{color}"
    end
  end

  class OrderWorkflow < Temporal::Workflow
    include Proxy::Communications # defines #receive_request, #receive_response, #send_error_response, #send_request, and #send_response

    timeouts start_to_close: 60

    def execute
      order = TShirtOrder.new
      setup_signal_handler

      # Loop until we receive a valid email
      loop do
        signal_detail = receive_request("email_payload")
        source_id, email = signal_detail.calling_workflow_id, signal_detail.value
        value, err = RegisterEmailActivity.execute(email)
        if err
          send_error_response(source_id, err)
          logger.warn "RegisterEmailActivity returned an error, loop back to top"
        else
          order.email = email

          send_response(source_id, SizeStage, "")
          break
        end
      end

      # Loop until we receive a valid size
      loop do
        signal_detail = receive_request("size_payload")
        source_id, size = signal_detail.calling_workflow_id, signal_detail.value
        future = ValidateSizeActivity.execute(size)

        future.failed do |exception|
          send_error_response(source_id, exception)
          logger.warn "ValidateSizeActivity returned an error, loop back to top"
        end

        future.done do
          order.size = size
          logger.info "ValidateSizeActivity succeeded, progress to next stage"
          send_response(source_id, ColorStage, "")
        end

        future.get # block waiting for response
        break unless future.failed?
      end

      # Loop until we receive a valid color
      loop do
        signal_detail = receive_request("color_payload")
        source_id, color = signal_detail.calling_workflow_id, signal_detail.value
        future = ValidateColorActivity.execute(color)

        future.failed do |exception|
          send_error_response(source_id, exception)
          logger.warn "ValidateColorActivity returned an error, loop back to top"
        end

        future.done do
          order.color = color
          logger.info "ValidateColorActivity succeeded, progress to next stage"
          send_response(source_id, ShippingStage, "")
        end

        future.get # block waiting for response
        break unless future.failed?
      end

      # #execute_workflow! blocks until child workflow exits with a result
      result = workflow.execute_workflow!(SynchronousProxy::ShippingWorkflow, workflow.metadata.id)
    end
  end

  class UpdateOrderWorkflow < Temporal::Workflow
    include Proxy::Communications
    timeouts start_to_close: 60

    def execute(order_workflow_id, stage, value)
      w_id = workflow.metadata.id
      setup_signal_handler
      status = OrderStatus.new({order_id: order_workflow_id, stage: stage})
      signal_workflow_execution_response = send_request(order_workflow_id, stage, value)

      signal_details = receive_response("#{stage}_stage_payload")
      logger.warn "UpdateOrderWorkflow received signal_details #{signal_details.inspect}, error? #{signal_details.error?}"
      return [status, signal_details.value] if signal_details.error?

      status.stage = signal_details.key # next stage
      [status, nil]
    end
  end

  class ShippingWorkflow < Temporal::Workflow
    # 5s timeout on Activities
    timeouts run: 60

    def execute(order_workflow_id)
      delivery_date, err = ScheduleDeliveryActivity.execute!(order_workflow_id)
      return err if err

      SendDeliveryEmailActivity.execute!(order_workflow_id, delivery_date)
    end
  end
end
