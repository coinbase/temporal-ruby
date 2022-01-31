module SynchronousProxy
  module Proxy
    # We support talking between two workflows using these helper methods. Each workflow
    # that wants to communicate will include this module. Unlike the Go examples which use
    # channels, the Ruby support is via #on_signal (to receive), Temporal.signal_workflow
    # (to send), and #wait_for (to block and wait for incoming signal).
    #
    # The basic trick is that we register a single #on_signal signal handler per workflow
    # via the #setup_signal_handler method. Each incoming signal is parsed to determine if
    # it's a request or response and then the appropriate ivar is set. After the signal handler
    # runs, this client executes the block attached to the #wait_for method to see if it
    # returns true. If the block evaluates that it has received a value into the ivar, it
    # returns true and unblocks.
    #
    module Communications
      RequestSignalName = "proxy-request-signal".freeze
      ResponseSignalName = "proxy-response-signal".freeze

      SignalDetails = Struct.new(
        :name, :key, :value, :error, :calling_workflow_id,
        keyword_init: true
      ) do
        def error?
          !!error
        end

        def to_input
          [calling_workflow_id, name, key, value, error]
        end

        def self.from_input(input)
          new({name: input[1], key: input[2], value: input[3], error: input[4], calling_workflow_id: input[0]})
        end
      end

      def setup_signal_handler
        w_id = workflow.metadata.id
        logger.info("#{self.class.name}#setup_signal_handler, Setup signal handler for workflow #{w_id}")

        workflow.on_signal do |signal, input|
          logger.info("#{self.class.name}#setup_signal_handler, Received signal for workflow #{w_id}")
          logger.warn "#{self.class.name}#setup_signal_handler, Signal received", { signal: signal, input: input }
          details = SignalDetails.from_input(input)

          case signal
          when RequestSignalName
            @request_signal = details

          when ResponseSignalName
            @response_signal = details

          else
            logger.warn "#{self.class.name}#setup_signal_handler, Unknown signal received"
          end
        end
      end

      def wait_for_response
        w_id = workflow.metadata.id
        # #workflow is defined as part of the Temporal::Workflow class and is therefore available to
        # any methods inside the class plus methods that are included from a Module like this one
        workflow.wait_for do
          logger.info("#{self.class.name}#wait_for_response, Awaiting #{ResponseSignalName} in #{w_id}")
          wait_result = !!@response_signal
          logger.info("#{self.class.name}#wait_for_response, response_signal [#{wait_result}] in #{w_id}")
          wait_result
        end
      end

      def wait_for_request
        w_id = workflow.metadata.id
        # #workflow is defined as part of the Temporal::Workflow class and is therefore available to
        # any methods inside the class plus methods that are included from a Module like this one
        workflow.wait_for do
          logger.info("#{self.class.name}#wait_for_request, Awaiting #{RequestSignalName} in #{w_id}")
          wait_result = !!@request_signal
          logger.info("#{self.class.name}#wait_for_request, request_signal [#{wait_result}] in #{w_id}")
          wait_result
        end
      end

      def send_error_response(target_workflow_id, err)
        w_id = workflow.metadata.id

        logger.info("#{self.class.name}#send_error_response, Sending error response from #{w_id} to #{target_workflow_id}")
        details = SignalDetails.new(key: "error", value: err, calling_workflow_id: w_id)
        Temporal.signal_workflow(workflow, ResponseSignalName, target_workflow_id, "", details.to_input)
        nil
      end

      def send_response(target_workflow_id, key, value)
        w_id = workflow.metadata.id

        logger.info("#{self.class.name}#send_response, Sending response from #{w_id} to #{target_workflow_id}")
        details = SignalDetails.new(key: key, value: value, calling_workflow_id: w_id)
        Temporal.signal_workflow(workflow, ResponseSignalName, target_workflow_id, "", details.to_input)
        nil
      end

      def send_request(target_workflow_id, key, value)
        w_id = workflow.metadata.id

        logger.info("#{self.class.name}#send_request, Sending request from #{w_id} to #{target_workflow_id}")
        logger.info "#{self.class.name}#send_request, key [#{key}], value [#{value}], calling_workflow_id [#{w_id}]"
        details = SignalDetails.new({key: key, value: value, calling_workflow_id: w_id})
        logger.info "#{self.class.name}#send_request, RequestSignalName #{RequestSignalName}, target_workflow_id #{target_workflow_id}, details #{details.to_input.inspect}"
        Temporal.signal_workflow(workflow, RequestSignalName, target_workflow_id, "", details.to_input)
        nil
      end

      def receive_response
        @response_signal = nil
        w_id = workflow.metadata.id
        Temporal.logger.info("#{self.class.name}#receive_response, Waiting for response in workflow #{w_id}")
        wait_for_response
        Temporal.logger.info("#{self.class.name}#receive_response, Got response and returning, in workflow #{w_id}")
        @response_signal
      end

      def receive_request
        @request_signal = nil
        w_id = workflow.metadata.id
        Temporal.logger.info("#{self.class.name}#receive_request, Waiting for request in workflow #{w_id}")
        wait_for_request
        Temporal.logger.info("#{self.class.name}#receive_request, Got request and returning, in workflow #{w_id}")
        @request_signal
      end
    end
  end
end
