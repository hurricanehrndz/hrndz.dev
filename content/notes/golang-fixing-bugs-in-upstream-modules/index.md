---
# vim: set ft=markdown tw=72:
title: Golang - fixing bugs in upstream modules
date: 2024-11-05T07:42:54-0700
lastmod: 2024-11-05T07:42:54-0700
draft: false
publish: true
aliases: [/notes/g0vb8jui/]
tags: [golang]
---

The cmd below will create a vendor folder that can be committed with
your code. Additionally, the modules in the vendor folder can be patched
to address upstream bugs.

```go
go mod vendor
```
