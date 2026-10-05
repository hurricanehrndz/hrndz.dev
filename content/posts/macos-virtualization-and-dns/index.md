---
# vim: set ft=markdown tw=72:
date: 2024-12-12T09:27:44-0700
lastmod: 2024-12-12T09:27:44-0700
draft: false
publish: true
aliases: [/posts/aopxsi5g/]
tags: [macOS, DNS, VMs]
title: "macOS virtualization and DNS"
---

Have you recently set up a macOS VM and encountered DNS resolution
issues? This post aims to explain why DNS resolution might fail in such
cases.

For those who may not know, the number of virtualization solutions for
macOS has significantly increased in recent years, thanks to Apple's
introduction of their Virtualization framework. However, like many Apple
products, the documentation can be somewhat lacking.

I experienced this issue firsthand when I set up a Sequoia VM on UTM and
found that the guest system couldn't resolve any addresses correctly.
This led me to investigate the problem, starting with the
[network capabilities of the framework][virt-net], but I found no
answers there. It wasn't until I monitored the host system that I
discovered the solution.

When you create a new VM with a shared network, the Virtualization
framework uses the host's [Internet Sharing][internet-sharing]
capabilities. Apple's Internet Sharing feature relies on several system
tools, including mDNSResponder. While mDNSResponder serves other native
functions, in virtualization, it acts as a DNS forwarder that listens on
all interfaces.

The problem arises if it can't listen on all interfaces, such as when
another DNS server is already listening on the loopback address. In this
situation, the Virtualization framework simply stops working. I would
argue that this is a bug because, technically, only the network bridge
that the VM connects to should need to listen for DNS requests.

You might wonder what other programs could be listening on port 53.
Surprisingly, many security tools do, focusing on protecting users from
malicious DNS entries. Examples include Cisco's Umbrella and
Cloudflare's Warp.

The only workarounds I have found are either to disable the security
tool, which defeats its purpose, or to run your own DNS forwarder. For
Umbrella, I choose to run another instance of
[dnscrypt-proxy][gh-dnscrypt-proxy], the default resolver included with
Umbrella. For Warp, you can simply use one of the readily available
forwarders, such as dnsmasq.

[gh-dnscrypt-proxy]: https://github.com/DNSCrypt/dnscrypt-proxy
[internet-sharing]: https://support.apple.com/en-ca/guide/mac-help/mchlp1540/mac
[virt-net]: https://developer.apple.com/documentation/virtualization/network
