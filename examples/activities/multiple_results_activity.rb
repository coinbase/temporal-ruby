class MultipleResultActivity < Temporal::Activity
  def execute
    return [1,2], { '1' => 2 }
  end
end
