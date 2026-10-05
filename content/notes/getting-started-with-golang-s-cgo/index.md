---
# vim: set ft=markdown tw=72:
date: 2024-11-04T16:40:30-0700
lastmod: 2024-11-04T20:55:44-0700
draft: false
publish: true
aliases: [/notes/72mxgkzm/]
tags: [golang]
title: "Getting started with golang's cgo"
---

```go
/*
#cgo LDFLAGS: -framework CoreFoundation

#include <CoreFoundation/CoreFoundation.h>
*/
```

Cgo recognizes the above comments. Lines starting with `#cgo` are
removed and passed to the compiler.

What remains (aka the [preamble]) is used as a header when
[compiling C parts of the package][cgo-blog]. `import "C"` must
immediately follow the preamble.

When using `//exports`, which exports a go function to `C`, the `C` code
in the comment (preamble) can include only declarations not definitions.
Except you can use [`static inline`][cgo-blog] as a workaround for
simple functions.

[cgo-blog]: https://go.dev/blog/cgo#
[preamble]: https://pkg.go.dev/cmd/cgo#hdr-Using_cgo_with_the_go_command
