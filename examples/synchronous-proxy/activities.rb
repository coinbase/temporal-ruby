module SynchronousProxy
  class RegisterEmailActivity < Temporal::Activity
    def execute(email)
      logger.info "activity: registered email #{email}"

      nil
    end
  end

  class ValidateSizeActivity < Temporal::Activity
    def execute(size)
      logger.info "activity: validate size #{size}"

      nil
    end
  end

  class ValidateColorActivity < Temporal::Activity
    def execute(color)
      logger.info "activity: validate color #{color}"

      nil
    end
  end

  class ScheduleDeliveryActivity < Temporal::Activity
    def execute(order)
      delivery_date = Time.now + (2 * 60 * 60 * 24)
      logger.info "activity: scheduled delivery for order #{order} at #{delivery_date}"
      [delivery_date, nil]
    end
  end

  class SendDeliveryEmailActivity < Temporal::Activity
    def execute(order, delivery_date)
      logger.info "email to: #{order.email}, order: #{order}, scheduled delivery: #{delivery_date}"
      nil
    end
  end
end
