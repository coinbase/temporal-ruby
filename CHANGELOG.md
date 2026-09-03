# Changelog

## 0.0.7

- `json/plain` no longer builds arbitrary Ruby classes from encoded payloads. That was possible because Oj object mode can allocate any constant named in the payload.
- Still round-trips first-party shapes: activity `Request` / `Response`, `Temporal::` types, Exception subclasses (including backtraces), `Date` / `DateTime` / `Rational`, anonymous Structs, and classes registered with `Temporal::JSON.allow_class`.
- Rejects duplicate JSON object keys. Oj and `JSON.parse` disagree on duplicates, so a discarded value could still allocate a class.
- Rejects constants that are only pending `autoload` until they are actually loaded.
- Rejects JSON nested deeper than 512 levels.
- Encoding name stays `json/plain`.
- Runtime depends on `google-protobuf` ~> 3.25 (generated stubs under `lib/gen/` require protobuf 3).

## 0.0.6

- Defer gRPC loading via autoload for fork safety
- Normalize replay attribute hash comparison for determinism

## 0.0.5

- Make poller threads configurable

## 0.0.4

- Patching

## 0.0.1

- First release
