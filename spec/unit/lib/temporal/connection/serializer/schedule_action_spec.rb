require "temporal/connection/errors"
require "temporal/schedule/start_workflow_action"
require "temporal/connection/serializer/schedule_action"

describe Temporal::Connection::Serializer::ScheduleAction do
  let(:timeouts) { {run: 100, task: 10} }

  let(:example_action) do
    Temporal::Schedule::StartWorkflowAction.new(
      "HelloWorldWorkflow",
      "one",
      "two",
      options: {
        workflow_id: "foobar",
        task_queue: "my-task-queue",
        timeouts: timeouts,
        memo: {:"foo-memo" => "baz"},
        search_attributes: {:"foo-search-attribute" => "qux"},
        headers: {:"foo-header" => "bar"}
      }
    )
  end

  describe "to_proto" do
    it "raises an error if an invalid action is specified" do
      expect do
        described_class.new(123).to_proto
      end
        .to(raise_error(Temporal::Connection::ArgumentError)) do |e|
          expect(e.message).to(eq("Unknown action type Integer"))
        end
    end

    it "produces well-formed protobuf" do
      result = described_class.new(example_action).to_proto

      expect(result).to(be_a(Temporalio::Api::Schedule::V1::ScheduleAction))

      action = result.start_workflow
      expect(action).to(be_a(Temporalio::Api::Workflow::V1::NewWorkflowExecutionInfo))
      expect(action.task_queue.name).to(eq("my-task-queue"))
      expect(action.input.payloads.map(&:data)).to(eq(["\"one\"", "\"two\""]))
      expect(action.header.fields["foo-header"].data).to(eq("\"bar\""))
      expect(action.memo.fields["foo-memo"].data).to(eq("\"baz\""))
      expect(action.search_attributes.indexed_fields["foo-search-attribute"].data).to(eq("\"qux\""))
      expect(action.workflow_run_timeout.seconds).to(eq(timeouts[:run]))
      expect(action.workflow_task_timeout.seconds).to(eq(timeouts[:task]))
    end
  end
end
