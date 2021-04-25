require 'activities/hello_world_activity'

class ComplexResultsWorkflow < Temporal::Workflow
  def execute
    result = SimpleResultActivity.execute!
    unless result == 'test'
      raise "simple test failed: #{result.inspect}"
    end

    result = ComplexResultActivity.execute!
    unless result == { '1' => 2, '3' => 4 }
      raise "complex test failed: #{result.inspect}"
    end

    result = MultipleResultActivity.execute!
    unless result == [[1,2] , { '1' => 2 }]
      raise "multiple test failed: #{result.inspect}"
    end

    return
  end
end
