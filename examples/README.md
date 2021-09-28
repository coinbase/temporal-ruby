# Ruby Temporal Examples

This directory contains examples demonstrating different features or this library and Temporal.

To try these out you need to have a running Temporal service ([setup instructions](https://github.com/coinbase/temporal-ruby#installing-dependencies)).

Install all the gem dependencies by running:

```sh
> bundle install
```

Modify the `init.rb` file to point to your Temporal cluster.

Start a worker process:

```sh
> bin/worker
```

Use this command to trigger one of the example workflows from the `workflows` directory:

```sh
> bin/trigger NAME_OF_THE_WORKFLOW [argument_1, argument_2, ...]
```
