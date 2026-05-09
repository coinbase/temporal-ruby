# Changelog

## 0.0.7

- Backport worker_may_ignore history event handling from the 0.1.x line
- Skip known Nexus/options-updated events and unknown worker-ignorable events
- Preserve fail-closed behavior for non-ignorable unknown events
- Make History::Event constructable when event attributes are unknown to the generated proto

## 0.0.6

- Defer gRPC loading via autoload for fork safety
- Normalize replay attribute hash comparison for determinism

## 0.0.5

- Make poller threads configurable

## 0.0.4

- Patching

## 0.0.1

- First release
