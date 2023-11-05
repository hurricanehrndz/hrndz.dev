---
public: "true"
slug: "add-additional-addresses-to-loopback-interface-on-macos"
tags: [macOS]
title: "Add additional addresses to loopback interface on macOS"
---

Adding secondary address to lo0
- ```console
  sudo ifconfig lo0 alias 127.0.0.2
  ```

To ensure secondary loopback address returns after reboot
- Create a launch daemon with the following contents:
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

- Start the launch daemon
  ```console
  sudo launchctl bootstrap system /Library/LaunchDaemons/dev.hrndz.ifconfig.plist
  ```
