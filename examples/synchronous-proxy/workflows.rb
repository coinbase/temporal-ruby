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

    timeouts start_to_close: 5

    def execute
      logger.info "Starting OrderWorkflow from the top"
      order = TShirtOrder.new
      setup_signal_handler

      # Loop until we receive a valid email
      loop do
        signal_detail = receive_request
        logger.info "ONE: signal_detail #{signal_detail.inspect}"
        source_id, email = signal_detail.calling_workflow_id, signal_detail.value
        value, err = RegisterEmailActivity.execute!(email)
        if err
          send_error_response(source_id, err)
          logger.warn "RegisterEmailActivity returned an error, loop back to top for #{workflow.id}"
          continue
        end

        order.email = email

        logger.warn "RegisterEmailActivity succeeded, go to SizeStage, send response"
        send_response(source_id, SizeStage, "")
        break
      end

      # sleep(15)
      # logger.info "ending OrderWorkflow #{workflow.metadata.id}, Exiting at #{Time.now}"
      # return nil

      # Loop until we receive a valid size
      loop do
        signal_detail = receive_request
        STDERR.puts "TWO: signal_detail #{signal_detail.inspect}"
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
        signal_detail = receive_request
        STDERR.puts "THREE: signal_detail #{signal_detail.inspect}"
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

    def execute(order_workflow_id, stage, value)
      setup_signal_handler
      logger.warn "UpdateOrderWorkflow, incoming args, order_workflow_id #{order_workflow_id.inspect}, stage [#{stage}], value [#{value}]"
      status = OrderStatus.new({order_id: order_workflow_id, stage: stage})
      logger.warn "UpdateOrderWorkflow, status was just setup #{status.inspect}"
      logger.info "UpdateOrderWorkflow #{order_workflow_id}, sending request for #{stage} with #{value}"
      signal_workflow_execution_response = send_request(order_workflow_id, stage, value)
      logger.info "UpdateOrderWorkflow #{order_workflow_id}, sent request, now waitin on response"

      signal_details = receive_response
      logger.info "UpdateOrderWorkflow #{order_workflow_id}, got response #{signal_details.inspect}"
      return [status, signal_details.error] if signal_details.error?
      logger.info "UpdateOrderWorkflow #{order_workflow_id}, increment stage value"

      status.stage = signal_details.key # next stage
      logger.info "ending UpdateOrderWorkflow #{order_workflow_id}"
      logger.info "UPDATEORDERWORKFLOW, status #{status.inspect}"
      [status, nil]
    end
  end

  class ShippingWorkflow < Temporal::Workflow
    # 5s timeout on Activities
    timeouts run: 5

    def execute(order_workflow_id, stage, value)
      delivery_date, err = ScheduleDeliveryActivity.execute!(order)
      return err if err

      err = SendDeliveryEmailActivity.execute!(order, delivery_date)
      return err
    end
  end
end
