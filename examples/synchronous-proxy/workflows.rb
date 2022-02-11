require_relative "proxy/communications"
require_relative "activities"

module SynchronousProxy
  RegisterStage = "register".freeze
  SizeStage = "size".freeze
  ColorStage = "color".freeze
  ShippingStage = "shipping".freeze

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
        value, err = RegisterEmailActivity.execute!(email)
        if err
          send_error_response(source_id, err)
          logger.warn "RegisterEmailActivity returned an error, loop back to top for #{workflow.id}"
          continue
        end

        order.email = email

        send_response(source_id, SizeStage, "")
        break
      end

      # Loop until we receive a valid size
      loop do
        signal_detail = receive_request("size_payload")
        source_id, size = signal_detail.calling_workflow_id, signal_detail.value
        value, err = ValidateSizeActivity.execute!(size)
        if err
          send_error_response(source_id, err)
          continue
        end

        order.size = size

        send_response(source_id, ColorStage, "")
        break
      end

      # Loop until we receive a valid color
      loop do
        signal_detail = receive_request("color_payload")
        source_id, color = signal_detail.calling_workflow_id, signal_detail.value
        value, err = ValidateColorActivity.execute!(color)
        if err
          send_error_response(source_id, err)
          continue
        end

        order.color = color

        send_response(source_id, ShippingStage, "")
        break
      end

      # #execute_workflow! blocks until child workflow exits with a result
      result = workflow.execute_workflow!(SynchronousProxy::ShippingWorkflow, order)
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
      return [status, signal_details.error] if signal_details.error?

      status.stage = signal_details.key # next stage
      [status, nil]
    end
  end

  class ShippingWorkflow < Temporal::Workflow
    # 5s timeout on Activities
    timeouts run: 60

    def execute(order_workflow_id, stage, value)
      delivery_date, err = ScheduleDeliveryActivity.execute!(order)
      return err if err

      err = SendDeliveryEmailActivity.execute!(order, delivery_date)
      err
    end
  end
end
