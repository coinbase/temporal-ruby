class HelloWorldActivity < Temporal::Activity
  def execute(name)
    text = "Hello World, #{name}"

    p text

    return text
  end
end
