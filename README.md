# ExRTCP

[![Hex.pm](https://img.shields.io/hexpm/v/ex_rtcp.svg)](https://hex.pm/packages/ex_rtcp)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/ex_rtcp)
[![CI](https://img.shields.io/github/actions/workflow/status/elixir-webrtc/ex_rtcp/ci.yml?logo=github&label=CI)](https://github.com/elixir-webrtc/ex_rtcp/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/elixir-webrtc/ex_rtcp/graph/badge.svg?token=0tlQeAdxhd)](https://codecov.io/gh/elixir-webrtc/ex_rtcp)

Implementation of the RTCP protocol in Elixir. 

Implements packet types from:
- [RFC 3550 - RTP: A Transport Protocol for Real-Time Applications](https://datatracker.ietf.org/doc/html/rfc3550)
- [RFC 4585 - Extended RTP Profile for Real-time Transport Control Protocol (RTCP)-Based Feedback (RTP/AVPF)](https://datatracker.ietf.org/doc/html/rfc4585)
- [RFC 5104 - Codec Control Messages in the RTP Audio-Visual Profile with Feedback (AVPF)](https://datatracker.ietf.org/doc/html/rfc5104)
- [RFC 8852 - RTP Stream Identifier Source Description (SDES)](https://datatracker.ietf.org/doc/html/rfc8852)
- [RTP Extensions for Transport-wide Congestion Control](https://datatracker.ietf.org/doc/html/draft-holmer-rmcat-transport-wide-cc-extensions-01)

For complete list of supported packet types, refer to the [documentation](https://hexdocs.pm/ex_rtcp/readme.html).

See [documentation page](https://hexdocs.pm/ex_rtcp/ExRTCP.Packet.html) of `ExRTCP.Packet` for usage examples.

## Installation

Add `ex_rtcp` to dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_rtcp, "~> 0.3.0"}
  ]
end
```

