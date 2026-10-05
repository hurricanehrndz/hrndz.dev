---
# vim: set ft=markdown tw=72:
date: 2024-11-20T08:11:02-0700
lastmod: 2024-11-20T08:11:02-0700
draft: false
publish: true
aliases: [/posts/kus8sygc/]
tags: [macOS, lima]
title: "Sharing localhost service with a remote network"
---

This past week I got asked a question that keeps arising from time to
time. How do I share a docker service that is running on my local
machine with a remote host and/or a remote network. For situations like
this, I tend to lean on ssh's remote port forwarding feature. Every
single time though I ended up looking up the information. So once and
for all I thought to myself, why don't I just write my own definitive
guide that makes sense to me.

In order to understand the solution, let's go over some details of the
systems and environment we are working with. The service is running on a
macOS (Sequoia) client. Docker is being run via [Lima][lima-home].
[Lima has been configure to bind port forwards to a loopback alias `127.0.0.3`](/notes/using-a-different-listening-address-with-lima/).
The remote system is Linux and the ssh daemon does not have
[`GatewayPorts`][ssh-academy] enabled.

With details out of the way, let's get the experiment setup.

## Start Nginx container

```console
docker run -d --rm -p 8000:80 nginx

```

Verify that nginx is running and response:

```console
curl -l 127.0.0.3:8000
```

## Forward local port to remote host

This is a simple ssh command, so let's have a see and then break it
down:

```console
ssh -R 44216:127.0.0.3:8000 remotehost
```

### Breaking down the command

***-R*** - Used to specify remote sockets, in our case a remote port,
will be forwarded to the client/local side. Args following flag
configures the specifics.

***44216*** - Remote port, only accessible on the remote host via the
loopback interface.

***:*** - Delineates remote parameters from local parameters. Left side
being the remote declarations, while the right side being the local.

***127.0.0.3:8000*** - IP and port of service running on client host.

## Expose port on remote host on all interfaces

If on the remote sshd daemon the `GatewayPorts` option is set to `yes`,
what follows should not be required. On the other hand if the option is
set to `no`, we will use gost's `PortForwarding` feature to expose the
forwarded port: 44216.

If you have been following along at this point nginx should be
accessible on the remote host via the loopback interface on port 44216.
You can confirm by running:

```console
curl -L localhost:44216
```

Now, we will expose the service by running a forwarding listener that
listens on all interfaces:

```console
gost -L tcp://:44217/127.0.0.1:44216
```

At this point the service running on the client should be accessible on
any routable IP of the remote host.

[lima-home]: https://lima-vm.io/
[ssh-academy]: https://www.ssh.com/academy/ssh/tunneling-example
