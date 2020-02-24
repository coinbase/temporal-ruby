# Cadence Proxy

A small executable that accepts incomming Thrift/HTTP requests and proxies them to Cadence server
using Thrift/TChannel.

## Why?

As of now Cadence only exposes Thrift via TChannel connection for its clients. And while Thrift
implementation is available for most languages, TChannel is not (supports only Go, Node, Python and
Java).

This makes it impossible for other language to connect to Cadence without implementing the whole
TChannel protocol from scratch.

This project solves the problem by exposing the Cadence interface via HTTP and proxies all the calls
to Cadence via TChannel.

## Compile

Build using:

```sh
> make
```

In order to update Thrift generated files:

```sh
> make thrift
```

## Run

Then execute with:

```sh
> bin/proxy
```

You can also specify the bind address and cadence address using env variables:

```sh
> BIND_ADDRESS=127.0.0.1:1234 CADENCE_ADDRESS=127.0.0.1:2345 bin/proxy
```

these default to

```
BIND_ADDRESS=127.0.0.1:6666
CADENCE_ADDRESS=127.0.0.1:7933
```
