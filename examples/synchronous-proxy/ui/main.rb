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
        loop do
          email = prompt_and_read_input("Please enter you email address:")
          status, err = update_order(random_id: random_id, sequence_no: sequence_no, order_id: status.order_id, stage: SynchronousProxy::RegisterStage, value: email)
          puts "status #{status.inspect}, err #{err.inspect}"
          break unless err

          STDERR.puts "invalid email"
        end

        sequence_no += 1
        loop do
          size = prompt_and_read_input("Please enter your requested size:")
          status, err = update_order(random_id: random_id, sequence_no: sequence_no, order_id: status.order_id, stage: SynchronousProxy::SizeStage, value: size)
          puts "status #{status.inspect}, err #{err.inspect}"
          break unless err

          STDERR.puts "invalid size"
        end

        sequence_no += 1
        loop do
          color = prompt_and_read_input("Please enter your required tshirt color:")
          status, err = update_order(random_id: random_id, sequence_no: sequence_no, order_id: status.order_id, stage: SynchronousProxy::ColorStage, value: color)
          puts "status #{status.inspect}, err #{err.inspect}"
          break unless err

          STDERR.puts "invalid color"
        end

        puts "Thanks for your order!"
        puts "You will receive an email with shipping details shortly"
        puts "Exiting at #{Time.now}"
      end

      def create_order(random_id, sequence_no)
        w_id = "new-tshirt-order-#{random_id}-#{sequence_no}"
        workflow_options = {task_queue: "ui-driven", workflow_id: w_id}
        Temporal.start_workflow(SynchronousProxy::OrderWorkflow, options: workflow_options)
        status = SynchronousProxy::OrderStatus.new
        status.order_id = w_id
        status
      end

      def update_order(random_id:, sequence_no:, order_id:, stage:, value:)
        w_id = "update_#{stage}_#{random_id}-#{sequence_no}"
        workflow_options = {task_queue: "ui-driven", workflow_id: w_id}
        run_id = Temporal.start_workflow(SynchronousProxy::UpdateOrderWorkflow, order_id, stage, value, options: workflow_options)
        status, err = Temporal.await_workflow_result(SynchronousProxy::UpdateOrderWorkflow, workflow_id: w_id, run_id: run_id)
        [status, err]
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
