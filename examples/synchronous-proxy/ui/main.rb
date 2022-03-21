require_relative "../configuration"
require_relative "../workflows"

module SynchronousProxy
  module UI
    class Main
      def run
        random_id = rand(999_999_999)
        sequence_no = 0
        status = create_order(random_id, sequence_no)

        sequence_no += 1
          email = prompt_and_read_input("Please enter you email address:")
          status = update_order(random_id: random_id, sequence_no: sequence_no, order_id: status.order_id, stage: SynchronousProxy::RegisterStage, value: email)
          puts "status #{status.inspect}"

        sequence_no += 1
        begin
          size = prompt_and_read_input("Please enter your requested size:")
          status = update_order(random_id: random_id, sequence_no: sequence_no, order_id: status.order_id, stage: SynchronousProxy::SizeStage, value: size)
          puts "status #{status.inspect}"
        rescue SynchronousProxy::ValidateSizeActivity::InvalidSize => e
          STDERR.puts e.message
          retry
        end

        sequence_no += 1
        begin
          color = prompt_and_read_input("Please enter your required tshirt color:")
          status = update_order(random_id: random_id, sequence_no: sequence_no, order_id: status.order_id, stage: SynchronousProxy::ColorStage, value: color)
          puts "status #{status.inspect}"
        rescue SynchronousProxy::ValidateColorActivity::InvalidColor => e
          STDERR.puts e.message
          retry
        end

        puts "Thanks for your order!"
        puts "You will receive an email with shipping details shortly"
        puts "Exiting at #{Time.now}"
      end

      def create_order(random_id, sequence_no)
        w_id = "new-tshirt-order-#{random_id}-#{sequence_no}"
        workflow_options = {workflow_id: w_id}
        Temporal.start_workflow(SynchronousProxy::OrderWorkflow, options: workflow_options)
        status = SynchronousProxy::OrderStatus.new
        status.order_id = w_id
        status
      end

      def update_order(random_id:, sequence_no:, order_id:, stage:, value:)
        w_id = "update_#{stage}_#{random_id}-#{sequence_no}"
        workflow_options = {workflow_id: w_id}
        run_id = Temporal.start_workflow(SynchronousProxy::UpdateOrderWorkflow, order_id, stage, value, options: workflow_options)
        Temporal.await_workflow_result(SynchronousProxy::UpdateOrderWorkflow, workflow_id: w_id, run_id: run_id)
      end

      def prompt_and_read_input(prompt)
        print(prompt + " ")
        gets.chomp
      end
    end
  end
end

if $0 == __FILE__
  SynchronousProxy::UI::Main.new.run
end
