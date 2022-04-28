require 'temporal/workflow/execution_info'

module Temporal
  class Workflow
    class Executions
      include Enumerable
  
      DEFAULT_REQUEST_OPTIONS = {
        next_page_token: nil
      }.freeze

      def initialize(connection:, status:, request_options:)
        @connection = connection
        @status = status
        @request_options = DEFAULT_REQUEST_OPTIONS.merge(request_options)
      end
      
      def next_page_token
        @request_options[:next_page_token]
      end

      def next_page
        self.class.new(connection: @connection, status: @status, request_options: @request_options.merge(next_page_token: next_page_token))
      end

      def each()
        api_method =
          if @status == :open
            :list_open_workflow_executions
          elsif @status == :closed
            :list_closed_workflow_executions
          else
            :query_workflow_executions
          end
        
        executions = []
        
        loop do
          response = @connection.public_send(
            api_method,
            **@request_options.merge(next_page_token: @request_options[:next_page_token])
          )

          paginated_executions = response.executions.map do |raw_execution|
            execution = Temporal::Workflow::ExecutionInfo.generate_from(raw_execution) 
            if block_given?
              yield execution
            end

            execution
          end

          @request_options[:next_page_token] = response.next_page_token

          return paginated_executions unless @request_options[:max_page_size].nil? # return after the first loop if set pagination size

          executions += paginated_executions

          break if @request_options[:next_page_token].to_s.empty?
        end

        executions
      end
    end
  end
end
