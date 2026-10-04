---
# vim: set ft=markdown tw=72:
title: KeepAlive GRPC on idle when using AWS ALB
date: 2024-11-05T07:50:51-0700
lastmod: 2024-11-05T07:50:51-0700
draft: false
publish: true
aliases: [/notes/g45fr844/]
tags: [golang]
---

[The AWS ALB does not support forwarding HTTP2 ping frames][so-grpc-http2-ping].
So to prevent `RST_STREAM` message with `ErrCode=PROTOCOL_ERROR`, one
must employ their own [dummy GRPC messages][ggroup-grpc-keepalive] to
keep the connection from idling.

[ggroup-grpc-keepalive]: https://groups.google.com/g/grpc-io/c/CUp2FPTritc/m/wsO_JTWNBQAJ
[so-grpc-http2-ping]: https://stackoverflow.com/questions/66818645/http2-ping-frames-over-aws-alb-grpc-keepalive-ping
