class HelloWorldActivity < Temporal::Activity
  def execute(name)
    p "Hello World, #{name}"

    return
  end
end
