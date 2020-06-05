class EchoActivity < Temporal::Activity
  def execute(text)
    p "ECHO: #{text}"
  end
end
