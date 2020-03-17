# Ruby worker for Cadence

<img src="./assets/cadence_logo_2.png" width="250" align="right" alt="Cadence" />

A pure Ruby library for defining and running Cadence workflows and activities.

To find more about Cadence please visit <https://cadenceworkflow.io/>.


## Getting Started

*NOTE: Make sure you have both Cadence and TChannel Proxy up and running. Head over to
[this section](#installing-dependencies) for installation instructions.*

Clone this repository:

```sh
> git clone git@github.com:coinbase/cadence-ruby.git
```

Include this gem to your `Gemfile`:

```ruby
gem 'cadence-ruby', path: 'path/to/a/cloned/cadence-ruby/'
```

Define an activity:

```ruby
class HelloActivity < Cadence::Workflow
  def execute(name)
    puts "Hello #{name}!"

    return
  end
end
```

Define a workflow:

```ruby
require 'path/to/hello_activity'

class HelloWorldWorkflow < Cadence::Workflow
  def execute
    HelloActivity.execute!('World')

    return
  end
end
```

Configure your Cadence connection:

```ruby
Cadence.configure do |config|
  config.host = 'localhost'
  config.port = 6666 # this should point to the tchannel proxy
  config.domain = 'ruby-samples'
  config.task_list = 'hello-world'
end
```

Register domain with the Cadence service:

```ruby
Cadence.register_domain('ruby-samples', 'A safe space for playing with Cadence Ruby')
```

Configure and start your worker process:

```ruby
require 'cadence/worker'

worker = Cadence::Worker.new
worker.register_workflow(HelloWorldWorkflow)
worker.register_activity(HelloActivity)
worker.start
```

And finally start your workflow:

```ruby
require 'path/to/hello_world_workflow'

Cadence.start_workflow(HelloWorldWorkflow)
```

Congratulation you've just created and executed a distributed workflow!

To view more details about your execution, point your browser to
<http://localhost:8088/domain/ruby-samples/workflows?range=last-3-hours&status=CLOSED>.

There are plenty of [runnable examples](examples/) demonstrating various features of this library
available, make sure to check them out.


## Installing dependencies

In order to run your Ruby workers you need to have the Cadence service and the TChannel Proxy
running. Below are the instructions on setting these up:

### Cadence

Cadence service handles all the persistence, fault tolerance and coordination of your workflows and
activities. To set it up locally, download and boot the Docker Compose file from the official repo:

```sh
> curl -O https://raw.githubusercontent.com/uber/cadence/master/docker/docker-compose.yml

> docker-compose up
```

### TChannel Proxy

Right now the Cadence service only communicates with the workers using Thrift over TChannel.
Unfortunately there isn't a working TChannel protocol implementation for Ruby, so in order to
connect to the Cadence service a simple proxy was created. You can run it using:

```sh
> cd proxy

> bin/proxy
```

The code and detailed instructions can be found [here](proxy/).


## Workflows

A workflow is defined using pure Ruby code, however it should contain only a high-level
deterministic outline of the steps (their composition) that need to be executed to complete a
workflow. The actual work should be defined in your activities.

*NOTE: Keep in mind that your workflow code can get run multiple times (replayed) during the same
execution, which is why it must NOT contain any non-deterministic code (network requests, DB
queries, etc) as it can break your workflows.*

Here's an example workflow:

```ruby
class RenewSubscriptionWorkflow < Cadence::Workflow
  def execute(user_id)
    subscription = FetchUserSubscriptionActivity.execute!(user_id)
    subscription ||= CreateUserSubscriptionActivity.execute!(user_id)

    return if subscription[:active]

    ChargeCreditCardActivity.execute!(subscription[:price], subscription[:card_token])

    RenewedSubscriptionActivity.execute!(subscription[:id])
    SendSubscriptionRenewalEmailActivity.execute!(user_id, subscription[:id])
  rescue CreditCardNotChargedError => e
    CancelSubscriptionActivity.execute!(subscription[:id])
    SendSubscriptionCancellationEmailActivity.execute!(user_id, subscription[:id])
  end
end
```

In this simple workflow we are checking if a user has an active subscription and then attempt to
charge their credit card to renew an expired subscription, notifying the user of the outcome. All
the work is encapsulated in activities, while the workflow itself is responsible for calling the
activities in the right order, passing values between them and handling failures.

There is a couple of ways to execute an activity from your workflow:

```ruby
# Calls the activity by its class and blocks the execution until activity is
# finished. The return value of your activity will get assigned to the result
result = MyActivity.execute!(arg1, arg2)

# Here's a non-blocking version of the execute, returning back the future that
# will get fulfilled when activity completes. This approach allows modelling
# asynchronous workflows with activities executed in parallel
future = MyActivity.execute(arg1, arg2)
result = future.get

# Full versions of the calls from above, but has more flexibility (shown below)
result = workflow.execute_activity!(MyActivity, arg1, arg2)
future = workflow.execute_activity(MyActivity, arg1, arg2)

# In case your workflow code does not have access to activity classes (separate
# process, activities implemented in a different language, etc), you can
# simply reference them by their names
workflow.execute_activity('MyActivity', arg1, arg2, options: { domain: 'my-domain', task_list: 'my-task-list' })
```

Besides calling activities workflows can:

- Use timers
- Receive signals
- Execute other (child) workflows [not yet implemented]
- Respond to queries [not yet implemented]


## Activities

An activity is a basic unit of work that performs the desired action (potentially causing
side-effects). It can return a result or raise an error. It is defined like so:

```ruby
class CloseUserAccountActivity < Cadence::Activity
  class UserNotFound < Cadence::ActivityException; end

  def execute(user_id)
    user = User.find_by(id: user_id)

    raise UserNotFound, 'User with specified ID does not exist' unless user

    user.close_account
    user.save

    AccountClosureEmail.deliver(user)

    return
  end
end
```

It is important to make your activities **idempotent**, because they can get retried by Cadence (in
case a timeout is reached or your activity has thrown an error). You normally want to avoid
generating additional side effects during subsequent activity execution.

To achieve this there are two methods (returning a UUID token) available from your activity class:

- `activity.run_idem` — unique within for the current workflow execution (scoped to run_id)
- `activity.workflow_idem` — unique across all execution of the workflow (scoped to workflow_id)

Both tokens will remain the same across multiple retry attempts of the activity.


## Worker

Worker is a process that communicates with the Cadence server and manages Workflow and Activity
execution. To start a worker:

```ruby
require 'cadence/worker'

worker = Cadence::Worker.new
worker.register_workflow(HelloWorldWorkflow)
worker.register_activity(SomeActivity)
worker.register_activity(SomeOtherActivity)
worker.start
```

A call to `worker.start` will take over the current process and will keep it unning until a `TERM`
or `INT` signal is received. By only registering a subset of your workflows/activities with a given
worker you can split processing across as many workers as you need.


## Starting a workflow

All communication is handled via Cadence service, so in order to start a workflow you need to send a
message to Cadence:

```ruby
Cadence.start_workflow(HelloWorldWorkflow)
```

Optionally you can pass input and other options to the workflow:

```ruby
Cadence.start_workflow(RenewSubscriptionWorkflow, user_id, options: { workflow_id: user_id })
```

Passing in a `workflow_id` allows you to prevent concurrent execution of a workflow — a subsequent
call with the same `workflow_id` will always get rejected while it is still running, raising
`CadenceThrift::WorkflowExecutionAlreadyStartedError`. You can adjust the behaviour for finished
workflows by supplying the `workflow_id_reuse_policy:` argument with one of these options:

- `:allow_failed` will allow re-running workflows that have failed (terminated, cancelled, timed out or failed)
- `:allow` will allow re-running any finished workflows both failed and completed
- `:reject` will reject any subsequent attempt to run a workflow


## Execution Options

There are lots of ways in which you can configure your Workflows and Activities. The common ones
(domain, task_list, timeouts and retry policy) can be defined in one of these places (in the order
of precedence):

1. Inline when starting or registering a workflow/activity (use `options:` argument)
2. In your workflow/activity class definitions by calling a class method (e.g. `domain 'my-domain'`)
3. Globally, when configuring your Cadence library via `Cadence.configure`


## Testing

It is crucial to properly test your workflows and activities before running them in production. The
provided testing framework is still limited in functionality, but will allow you to test basic
use-cases.

The testing framework is not required automatically when you require `cadence-ruby`, so you have to
do this yourself (it is strongly recommended to only include this in your test environment,
`spec_helper.rb` or similar):

```ruby
require 'cadence/testing'
```

This will allow you to execute workflows locally by running `HelloWorldWorkflow.execute_locally`.
Any arguments provided will forwarded to your `#execute` method.

In case of a higher level end-to-end integration specs, where you need to execute a Cadence workflow
as part of your code, you can enable local testing:

```ruby
Cadence::Testing.local!
```

This will treat every `Cadence.start_workflow` call as local and perform your workflows inline. It
also works with a block, restoring the original mode back after the execution:

```ruby
Cadence::Testing.local! do
  Cadence.start_workflow(HelloWorldWorkflow)
end
```

Make sure to check out [example integration specs](examples/specs/integration) for more details.


## TODO

There's plenty of work to be done, but most importanly we need:

- Write specs for everything
- Implement support for missing features


## LICENSE

Copyright 2020 Coinbase, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
