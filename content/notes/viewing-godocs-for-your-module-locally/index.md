---
# vim: set ft=markdown tw=72:
date: 2024-11-05T07:48:47-0700
lastmod: 2025-02-28T17:51:16-0700
draft: false
publish: true
aliases: [/notes/76uml9ly/]
tags: [golang]
title: "Viewing godocs for your module locally"
---

## Install `pkgsite`

```console
go install golang.org/x/pkgsite/cmd/pkgsite@latest
```

## Serve docs from current directory module

```console
pkgsite
```
