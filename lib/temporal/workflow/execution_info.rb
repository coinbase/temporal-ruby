require 'temporal/workflow/status'

module Temporal
  class Workflow
    class ExecutionInfo < Struct.new(:workflow, :workflow_id, :run_id, :start_time, :close_time, :status,
                                     :history_length, :memo, :search_attributes, keyword_init: true)

      STATUSES = [
        Temporal::Workflow::Status::RUNNING,
        Temporal::Workflow::Status::COMPLETED,
        Temporal::Workflow::Status::FAILED,
        Temporal::Workflow::Status::CANCELED,
        Temporal::Workflow::Status::TERMINATED,
        Temporal::Workflow::Status::CONTINUED_AS_NEW,
        Temporal::Workflow::Status::TIMED_OUT
      ]

      def self.generate_from(response, converter)
        search_attributes = response.search_attributes.nil? ? {} : converter.from_payload_map_without_codec(response.search_attributes.indexed_fields)
        new(
          workflow: response.type.name,
          workflow_id: response.execution.workflow_id,
          run_id: response.execution.run_id,
          start_time: response.start_time&.to_time,
          close_time: response.close_time&.to_time,
          status: Temporal::Workflow::Status::API_STATUS_MAP.fetch(response.status),
          history_length: response.history_length,
          memo: converter.from_payload_map(response.memo.fields),
          search_attributes: converter.search_attributes
        ).freeze
      end

      STATUSES.each do |status|
        define_method("#{status.downcase}?") do
          self.status == status
        end
      end

      def closed?
        !running?
      end
    end
  end
end
