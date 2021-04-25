class ComplexResultActivity < Temporal::Activity
  def execute
    return { '1' => 2, '3' => 4 }
  end
end
