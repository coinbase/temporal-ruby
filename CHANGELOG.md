# Changelog

## 0.0.7

- Fail-closed `json/plain` deserialize: Oj `mode: :object` no longer instantiates arbitrary classes. Duplicate hash keys (including container-valued keys) and excessive nesting are rejected in an Oj::Saj pass before load. Directive validation resolves only already-loaded constants and does not trigger `autoload`. Instances are reconstituted only for loaded `Temporal::` types, loaded `::Request` / `::Response` types, loaded Exception subclasses (error serialization v2), Oj odd-marshaller types (`Date`, `DateTime`, `Rational`), Oj Exception backtrace types (`Thread::Backtrace`), and `Temporal::JSON.allow_class`. Anonymous Structs (`^u` with member names) round-trip. Class references (`^c`) require a loaded constant. Encode and the `json/plain` encoding name are unchanged.
- Declare runtime dependency on `google-protobuf` ~> 3.25 (generated stubs under `lib/gen/` require protobuf 3).

## 0.0.6

- Defer gRPC loading via autoload for fork safety
- Normalize replay attribute hash comparison for determinism

## 0.0.5

- Make poller threads configurable

## 0.0.4

- Patching

## 0.0.1

- First release
