# Ruby Cadence Examples

This directory contains examples demonstraiting different features or this library and Cadence.

To try these out you need to have Cadence and TChannel Proxy running ([setup instructions](https://github.com/coinbase/cadence-ruby#installing-dependencies)).

Install all the gem dependencies by running:

```sh
> bundle install
```

Modify the `init.rb` file to point to your TChannel Proxy.

Start a worker process:

```sh
> bin/worker
```

Use this command to trigger one of the example workflows from the `workflows` directory:

```sh
> bin/trigger NAME_OF_THE_WORKFLOW [argument_1, argument_2, ...]
```
