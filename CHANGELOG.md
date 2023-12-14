# Changelog

## 0.2.0
Expose two new configurations
  - `client_config`: define the configurations for the workflow client
  - `payload_converters_options`: define the configuration for the payload converters

## 0.1.1
Allows signals to be processed within the first workflow task.

**IMPORTANT:** This change is backward compatible, but workflows started
on this version cannot run on earlier versions. If you roll back, you will
see workflow task failures mentioning an unknown SDK flag. This will prevent
those workflows from making progress until your code is rolled forward
again. If you'd like to roll this out more gradually, you can,
1. Set the `no_signals_in_first_task` configuration option to `true`
2. Deploy your worker
3. Wait until you are certain you won't need to roll back
4. Remove the configuration option, which will default it to `false`
5. Deploy your worker

## 0.1.0

This introduces signal first ordering. See https://github.com/coinbase/temporal-ruby/issues/258 for
details on why this is necessary for correct handling of signals.

**IMPORTANT: ** This feature requires Temporal server 1.20.0 or newer. If you are running an older
version of the server, you must either upgrade to at least this version, or you can set the
`.legacy_signals` configuration option to true until you can upgrade.

If you do not have existing workflows with signals running or are standing up a worker service
for the first time, you can ignore all the below instructions.

If you have any workflows with signals running during a deployment and run more than one worker
process, you must follow these rollout steps to avoid non-determinism errors:
1. Set `.legacy_signals` in `Temporal::Configuration` to true
2. Deploy your worker
3. Remove the `.legacy_signals` setting or set it to `false`
4. Deploy your worker

These steps ensure any workflow that executes in signals first mode will continue to be executed
in this order on replay. If you don't follow these steps, you may see failed workflow tasks, which
in some cases could result in unrecoverable history corruption.
