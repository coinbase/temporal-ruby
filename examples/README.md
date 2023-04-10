# Ruby Temporal Examples

This directory contains examples demonstrating different features or this library and Temporal.

To try these out you need to have a running Temporal service ([setup instructions](https://github.com/coinbase/temporal-ruby#installing-dependencies)).

Install all the gem dependencies by running:

```sh
bundle install
```

Modify the `init.rb` file to point to your Temporal cluster.

Start the three worker processes. Each of these uses a different task queue because there are differences
in how their payloads are serialized. You typically want to do this by running each line in a separate
terminal or via tmux or similar.

```sh
bin/worker
USE_ENCRYPTION=1 bin/worker
USE_ERROR_SERIALIZATION_V2=1 bin/worker
```

Use this command to trigger one of the example workflows from the `workflows` directory:

```sh
bin/trigger NAME_OF_THE_WORKFLOW [argument_1, argument_2, ...]
```
## Testing

To run tests, make sure the temporal server is running:
```shell
docker-compose up
```

Follow the instructions above to start the three worker proceses.

To execute the tests, run:
```shell
bundle exec rspec
```
To add a new test that uses a new workflow or new activity, make sure to register those new
workflows and activities by modifying the `bin/worker` file and adding them there. After any
changes to that file, restart the worker process to pick up the new registrations.
