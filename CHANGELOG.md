# Changelog

## 0.0.7

- Fail-closed `json/plain` deserialize: Oj `mode: :object` no longer instantiates arbitrary classes. Instances are reconstituted only for loaded `Temporal::` types, loaded `::Request` / `::Response` types, loaded Exception subclasses (error serialization v2), Oj Exception backtrace types (`Thread::Backtrace`), and `Temporal::JSON.allow_class`. Anonymous Structs (`^u` with member names) round-trip. Class references (`^c`) require a loaded constant. Encode and the `json/plain` encoding name are unchanged (SECBUGS-174).

## 0.0.6

- Defer gRPC loading via autoload for fork safety
- Normalize replay attribute hash comparison for determinism

## 0.0.5

- Make poller threads configurable

## 0.0.4

- Patching

## 0.0.1

- First release
