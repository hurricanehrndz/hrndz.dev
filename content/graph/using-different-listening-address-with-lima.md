---
public: "true"
slug: "using-different-listening-address-with-lima"
tags: [macOS, lima, docker]
title: "Using different listening address with lima"
---

Apppend the following to the lima.yaml file of the guest under portForwards, i.e. `~/.lima/docker/lima.yaml`
- ```
    - guestIP: "127.0.0.1"
      guestPortRange: [1, 65535]
      hostIP: "127.0.0.2"
  ```

Restart lima host
- ```sh
  limactl stop docker
  limactl start docker
  ```

Setting the forwarding address at create
- ```sh
  --set .portForwards +=[{ "guestIP": "127.0.0.1", hostIP: "127.0.0.2"}]
  ```
