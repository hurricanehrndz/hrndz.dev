---
# vim: set ft=markdown tw=72:
title: Using a different listening address with lima
date: 2023-11-05T16:05:31-0700
lastmod: 2025-03-13T17:02:09-0600
draft: false
publish: true
aliases: [/notes/gc4ct1zb/]
tags: [docker, macOS]
---

Append the following to the lima.yaml file of the guest under
portForwards, i.e. `~/.lima/docker/lima.yaml`

```yml
- guestIP: "127.0.0.1"
  hostIP: "127.0.0.2"
```

Restart lima host

```console
  limactl stop docker
  limactl start docker
```

Setting the forwarding address at creation of VM, append these arguments
to the command:

```console
  --set .portForwards +=[{ "guestIP": "127.0.0.1", hostIP: "127.0.0.2"}]
```
