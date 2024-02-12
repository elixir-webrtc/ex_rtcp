# ExRTCP

[![Hex.pm](https://img.shields.io/hexpm/v/ex_rtcp.svg)](https://hex.pm/packages/ex_rtcp)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/ex_rtcp)
[![CI](https://img.shields.io/github/actions/workflow/status/elixir-webrtc/ex_rtcp/ci.yml?logo=github&label=CI)](https://github.com/elixir-webrtc/ex_rtcp/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/elixir-webrtc/ex_rtcp/graph/badge.svg?token=0tlQeAdxhd)](https://codecov.io/gh/elixir-webrtc/ex_rtcp)

Implementation of the RTCP protocol in Elixir. 

Implements packet types from:
- [RFC 3550 - RTP: A Transport Protocol for Real-Time Applications](https://datatracker.ietf.org/doc/html/rfc3550)
- [RTP Extensions for Transport-wide Congestion Control](https://datatracker.ietf.org/doc/html/draft-holmer-rmcat-transport-wide-cc-extensions-01)

## Installation

Add `ex_rtcp` to dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_rtcp, "~> 0.2.0"}
  ]
end
```

