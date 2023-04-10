# Ruby SDK for Temporal

[![Coverage Status](https://coveralls.io/repos/github/coinbase/temporal-ruby/badge.svg?branch=master)](https://coveralls.io/github/coinbase/temporal-ruby?branch=master)

<img src="./assets/temporal_logo.png" width="250" align="right" alt="Temporal" />

A pure Ruby library for defining and running Temporal workflows and activities.

To find more about Temporal itself please visit <https://temporal.io/>.


## Getting Started

Clone this repository:

```sh
git clone git@github.com:coinbase/temporal-ruby.git
```

Include this gem to your `Gemfile`:

```ruby
gem 'temporal-ruby', github: 'coinbase/temporal-ruby'
```

Define an activity:

```ruby
require 'temporal-ruby'
class HelloActivity < Temporal::Activity
  def execute(name)
    puts "Hello #{name}!"

    return nil
  end
end
```

Define a workflow:

```ruby
require 'path/to/hello_activity'

class HelloWorldWorkflow < Temporal::Workflow
  def execute
    HelloActivity.execute!('World')

    return nil
  end
end
```

Configure your Temporal connection and register the namespace with the Temporal service:

```ruby
require 'temporal-ruby'
Temporal.configure do |config|
  config.host = 'localhost'
  config.port = 7233
  config.namespace = 'ruby-samples'
  config.task_queue = 'hello-world'
  config.credentials = :this_channel_is_insecure
end

begin
  Temporal.register_namespace('ruby-samples', 'A safe space for playing with Temporal Ruby')
rescue Temporal::NamespaceAlreadyExistsFailure
  nil # service was already registered
end
```


Configure and start your worker process in a terminal shell:

```ruby
require 'path/to/configuration'
require 'temporal/worker'

worker = Temporal::Worker.new
worker.register_workflow(HelloWorldWorkflow)
worker.register_activity(HelloActivity)
worker.start # runs forever
```

And finally start your workflow in another terminal shell:

```ruby
require 'path/to/configuration'
require 'path/to/hello_world_workflow'

Temporal.start_workflow(HelloWorldWorkflow)
```

Congratulation you've just created and executed a distributed workflow!

To view more details about your execution, point your browser to
<http://localhost:8088/namespace/ruby-samples/workflows?range=last-3-hours&status=CLOSED>.

There are plenty of [runnable examples](examples/) demonstrating various features of this library
available, make sure to check them out.


## Installing dependencies

Temporal service handles all the persistence, fault tolerance and coordination of your workflows and
activities. To set it up locally, download and boot the Docker Compose file from the official repo.
The Docker Compose file forwards all ports to your localhost so you can interact with
the containers easily from your shells.

Run:

```sh
curl -O https://raw.githubusercontent.com/temporalio/docker-compose/main/docker-compose.yml

docker-compose up
```

## Using Credentials

### SSL

In many production deployments you will end up connecting to your Temporal Services via SSL. In this
case you must read the public certificate of the CA that issued your Temporal server's SSL certificate and create
an instance of [gRPC Channel Credentials](https://grpc.io/docs/guides/auth/#with-server-authentication-ssltls-1).

Configure your Temporal connection:

```ruby
Temporal.configure do |config|
    config.host = 'localhost'
    config.port = 7233
    config.namespace = 'ruby-samples'
    config.task_queue = 'hello-world'
    config.credentials = GRPC::Core::ChannelCredentials.new(root_cert, client_key, client_chain)
end
```

### OAuth2 Token

Use gRPC Call Credentials to add OAuth2 token to gRPC calls:

```ruby
Temporal.configure do |config|
    config.host = 'localhost'
    config.port = 7233
    config.namespace = 'ruby-samples'
    config.task_queue = 'hello-world'
    config.credentials = GRPC::Core::CallCredentials.new(updater_proc)
end
```
`updater_proc` should be a method that returns `proc`. See an example of `updater_proc` in [googleauth](https://www.rubydoc.info/gems/googleauth/0.1.0/Signet/OAuth2/Client) library.

### Combining Credentials

To configure both SSL and OAuth2 token cedentials use `compose` method:

```ruby
Temporal.configure do |config|
    config.host = 'localhost'
    config.port = 7233
    config.namespace = 'ruby-samples'
    config.task_queue = 'hello-world'
    config.credentials = GRPC::Core::ChannelCredentials.new(root_cert, client_key, client_chain).compose(
        GRPC::Core::CallCredentials.new(token.updater_proc)
    )
end
```

## Workflows

A workflow is defined using pure Ruby code, however it should contain only a high-level
deterministic outline of the steps (their composition) that need to be executed to complete a
workflow. The actual work should be defined in your activities.

*NOTE: Keep in mind that your workflow code can get run multiple times (replayed) during the same
execution, which is why it must NOT contain any non-deterministic code (network requests, DB
queries, etc) as it can break your workflows.*

Here's an example workflow:

```ruby
class RenewSubscriptionWorkflow < Temporal::Workflow
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
workflow.execute_activity('MyActivity', arg1, arg2, options: { namespace: 'my-namespace', task_queue: 'my-task-queue' })
```

Besides calling activities workflows can:

- Use timers
- Receive signals
- Execute other (child) workflows
- Respond to queries


## Activities

An activity is a basic unit of work that performs the desired action (potentially causing
side-effects). It can return a result or raise an error. It is defined like so:

```ruby
class CloseUserAccountActivity < Temporal::Activity
  class UserNotFound < Temporal::ActivityException; end

  def execute(user_id)
    user = User.find_by(id: user_id)

    raise UserNotFound, 'User with specified ID does not exist' unless user

    user.close_account
    user.save

    AccountClosureEmail.deliver(user)

    return nil
  end
end
```

It is important to make your activities **idempotent**, because they can get retried by Temporal (in
case a timeout is reached or your activity has thrown an error). You normally want to avoid
generating additional side effects during subsequent activity execution.

To achieve this there are two methods (returning a UUID token) available from your activity class:

- `activity.run_idem` — unique within for the current workflow execution (scoped to run_id)
- `activity.workflow_idem` — unique across all execution of the workflow (scoped to workflow_id)

Both tokens will remain the same across multiple retry attempts of the activity.

### Asynchronous completion

When dealing with asynchronous business logic in your activities, you might need to wait for an
external event to complete your activity (e.g. a callback or a webhook). This can be achieved by
manually completing your activity using a provided `async_token` from activity's context:

```ruby
class AsyncActivity < Temporal::Activity
  def execute(user_id)
    user = User.find_by(id: user_id)

    # Pass the async_token to complete your activity later
    ExternalSystem.verify_user(user, activity.async_token)

    activity.async # prevents activity from completing immediately
  end
end
```

Later when a confirmation is received you'll need to complete your activity manually using the token
provided:

```ruby
Temporal.complete_activity(async_token, result)
```

Similarly you can fail the activity by calling:

```ruby
Temporal.fail_activity(async_token, MyError.new('Something went wrong'))
```

This doesn't change the behaviour from the workflow's perspective — as any other activity the result
will be returned or an error raised.

*NOTE: Make sure to configure your timeouts accordingly and not to set heartbeat timeout (off by
default) since you won't be able to emit heartbeats and your async activities will keep timing out.*

Similar behaviour can also be achieved in other ways (one which might be more preferable in your
specific use-case), e.g.:

- by polling for a result within your activity (long-running activities with heartbeat)
- using retry policy to keep retrying activity until a result is available
- completing your activity after the initial call is made, but then waiting on a completion signal
from your workflow


## Worker

Worker is a process that communicates with the Temporal server and manages Workflow and Activity
execution. To start a worker:

```ruby
require 'temporal/worker'

worker = Temporal::Worker.new
worker.register_workflow(HelloWorldWorkflow)
worker.register_activity(SomeActivity)
worker.register_activity(SomeOtherActivity)
worker.start
```

A call to `worker.start` will take over the current process and will keep it unning until a `TERM`
or `INT` signal is received. By only registering a subset of your workflows/activities with a given
worker you can split processing across as many workers as you need.


## Starting a workflow

All communication is handled via Temporal service, so in order to start a workflow you need to send
a message to Temporal:

```ruby
Temporal.start_workflow(HelloWorldWorkflow)
```

Optionally you can pass input and other options to the workflow:

```ruby
Temporal.start_workflow(RenewSubscriptionWorkflow, user_id, options: { workflow_id: user_id })
```

Passing in a `workflow_id` allows you to prevent concurrent execution of a workflow — a subsequent
call with the same `workflow_id` will always get rejected while it is still running, raising
`Temporal::WorkflowExecutionAlreadyStartedFailure`. You can adjust the behaviour for finished
workflows by supplying the `workflow_id_reuse_policy:` argument with one of these options:

- `:allow_failed` will allow re-running workflows that have failed (terminated, cancelled, timed out or failed)
- `:allow` will allow re-running any finished workflows both failed and completed
- `:reject` will reject any subsequent attempt to run a workflow


## Execution Options

There are lots of ways in which you can configure your Workflows and Activities. The common ones
(namespace, task_queue, timeouts and retry policy) can be defined in one of these places (in the order
of precedence):

1. Inline when starting or registering a workflow/activity (use `options:` argument)
2. In your workflow/activity class definitions by calling a class method (e.g. `namespace 'my-namespace'`)
3. Globally, when configuring your Temporal library via `Temporal.configure`


## Periodic workflow execution

In certain cases you might need a workflow that runs periodically using a cron schedule. This can be
achieved using the `Temporal.schedule_workflow` API that take a periodic cron schedule as a second
argument:

```ruby
Temporal.schedule_workflow(HealthCheckWorkflow, '*/5 * * * *')
```

This will instruct Temporal to run a HealthCheckWorkflow every 5 minutes. All the rest of the
arguments are identical to the `Temporal.start_workflow` API.

*NOTE: Your execution timeout will be measured across all the workflow invocations, so make sure to
set it to allow as many invocations as you need. You can also set it to `nil`, which will use a
default value of 10 years.*


## Breaking Changes

Since the workflow execution has to be deterministic, breaking changes can not be simply added and
deployed — this will undermine the consistency of running workflows and might lead to unexpected
behaviour. However, breaking changes are often needed and these include:

- Adding new activities, timers, child workflows, etc.
- Remove existing activities, timers, child workflows, etc.
- Rearranging existing activities, timers, child workflows, etc.
- Adding/removing signal handlers

In order to add a breaking change you can use `workflow.has_release?(release_name)` method in your
workflows, which is guaranteed to return a consistent result whether or not it was called prior to
shipping the new release. It is also consistent for all the subsequent calls with the same
`release_name` — all of them will return the original result. Consider the following example:

```ruby
class MyWorkflow < Temporal::Workflow
  def execute
    ActivityOld1.execute!

    workflow.sleep(10)

    ActivityOld2.execute!

    return nil
  end
end
```

which got updated to:

```ruby
class MyWorkflow < Temporal::Workflow
  def execute
    Activity1.execute!

    if workflow.has_release?(:fix_1)
      ActivityNew1.execute!
    end

    workflow.sleep(10)

    if workflow.has_release?(:fix_1)
      ActivityNew2.execute!
    else
      ActivityOld.execute!
    end

    if workflow.has_release?(:fix_2)
      ActivityNew3.execute!
    end

    return nil
  end
end
```

If the release got deployed while the original workflow was waiting on a timer, `ActivityNew1` and
`ActivityNew2` won't get executed, because they are part of the same change (same release_name),
however `ActivityNew3` will get executed, since the release wasn't yet checked at the time. And for
every new execution of the workflow — all new activities will get executed, while `ActivityOld` will
not.

Later on you can clean it up and drop all the checks if you don't have any older workflows running
or expect them to ever be executed (e.g. reset).

*NOTE: Releases with different names do not depend on each other in any way.*

## Testing

It is crucial to properly test your workflows and activities before running them in production. The
provided testing framework is still limited in functionality, but will allow you to test basic
use-cases.

The testing framework is not required automatically when you require `temporal-ruby`, so you have to
do this yourself (it is strongly recommended to only include this in your test environment,
`spec_helper.rb` or similar):

```ruby
require 'temporal/testing'
```

This will allow you to execute workflows locally by running `HelloWorldWorkflow.execute_locally`.
Any arguments provided will forwarded to your `#execute` method.

In case of a higher level end-to-end integration specs, where you need to execute a Temporal workflow
as part of your code, you can enable local testing:

```ruby
Temporal::Testing.local!
```

This will treat every `Temporal.start_workflow` call as local and perform your workflows inline. It
also works with a block, restoring the original mode back after the execution:

```ruby
Temporal::Testing.local! do
  Temporal.start_workflow(HelloWorldWorkflow)
end
```

Make sure to check out [example integration specs](examples/spec/integration) for more details. Instructions
for running these integration specs can be found in [examples/README.md](examples/README.md).


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
