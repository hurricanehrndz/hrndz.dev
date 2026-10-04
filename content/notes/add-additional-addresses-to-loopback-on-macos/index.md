---
# vim: set ft=markdown tw=72:
title: Add additional addresses to loopback on macOS
date: 2023-11-05T16:13:33-0700
lastmod: 2023-11-05T16:13:33-0700
draft: false
publish: true
aliases: [/notes/rcxhexvs/]
tags: [macOS]
---

Adding secondary address to lo0

```console
sudo ifconfig lo0 alias 127.0.0.2
```

To ensure the secondary address persist after reboots Create a launch
daemon with the following contents:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>dev.hrndz.ifconfig</string>
    <key>RunAtLoad</key>
    <true/>
    <key>ProgramArguments</key>
    <array>
    <string>/sbin/ifconfig</string>
    <string>lo0</string>
    <string>alias</string>
    <string>127.0.0.2</string>
    </array>
</dict>
</plist>
```

Finally, start the launch daemon

```console
sudo launchctl bootstrap system /Library/LaunchDaemons/dev.hrndz.ifconfig.plist
```
