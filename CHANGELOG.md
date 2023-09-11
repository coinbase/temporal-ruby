# Changelog

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