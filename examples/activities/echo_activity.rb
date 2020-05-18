class EchoActivity < Cadence::Activity
  def execute(text)
    p "ECHO: #{text}"
  end
end
