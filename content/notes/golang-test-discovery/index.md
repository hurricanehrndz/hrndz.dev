---
# vim: set ft=markdown tw=72:
title: Golang test discovery
date: 2024-11-05T07:44:43-0700
lastmod: 2024-11-05T07:44:43-0700
draft: false
publish: true
aliases: [/notes/ht0tq8ge/]
tags: [golang]
---

For every file ending with \_test.go, it runs every function that
matches either:

- Example\[A-Z\_\].\*
- Test\[A-Z\_\].\*

You can use the [assert package][assertpkg] for tests, and examples
functions may include a line comment that begins with
["Output:"][examples] to verify stdout.

[assertpkg]: https://pkg.go.dev/github.com/stretchr/testify/assert
[examples]: https://pkg.go.dev/testing#hdr-Examples
