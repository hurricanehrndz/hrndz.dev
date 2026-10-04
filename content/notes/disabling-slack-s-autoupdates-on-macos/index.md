---
# vim: set ft=markdown tw=72:
title: Disabling slack's autoupdates on macOS
date: 2024-11-06T07:53:05-0700
lastmod: 2024-11-06T07:53:05-0700
draft: false
publish: true
aliases: [/notes/fx9qzfpn/]
tags: [macOS]
---

You will need to create a custom profile on Jamf, this is best done by
using the `upload` feature of "Application & Custom Setting". For the
application domain use [`com.tinyspeck.slackmacgap`][slack-docs] and
then upload the following:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
  <key>AutoUpdate</key>
  <false/>
  </dict>
</plist>
```

If you already had deployed a profile previously, it may be time to
revisit your settings.
[Slack deprecated the old key in October of 2024][slack-deprecation].

## References

- [An update on disabling slack auto updates][disable-slack-updates]

[disable-slack-updates]: https://rickheil.com/an-update-on-disabling-slack-auto-updates/
[slack-deprecation]: https://slack.com/help/articles/4426294050451-Slack-feature-retirements#:~:text=As%20of%20June%2024%2C%202024,until%20they%20are%20fully%20deprecated.
[slack-docs]: https://slack.com/help/articles/11906214948755-Manage-desktop-app-configurations#mac-2
