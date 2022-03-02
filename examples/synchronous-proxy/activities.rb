module SynchronousProxy
  class RegisterEmailActivity < Temporal::Activity
    def execute(email)
      logger.info "activity: registered email #{email}"
      nil
    end
  end

  class ValidateSizeActivity < Temporal::Activity
    InvalidSize = Class.new(StandardError)

    retry_policy(
      interval: 1,
      backoff: 1,
      max_attempts: 3,
      non_retriable_errors: [InvalidSize])

    def execute(size)
      logger.info "activity: validate size #{size}"
      return nil if TShirtSizes.include?(size)

      raise InvalidSize.new("#{size} is not a valid size choice.")
    end
  end

  class ValidateColorActivity < Temporal::Activity
    InvalidColor = Class.new(StandardError)

    retry_policy(
      interval: 1,
      backoff: 1,
      max_attempts: 3,
      non_retriable_errors: [InvalidColor])

    def execute(color)
      logger.info "activity: validate color #{color}"
      return nil if TShirtColors.include?(color)

      raise InvalidColor.new("#{color} is not a valid color choice.")
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
