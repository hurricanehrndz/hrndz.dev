---
# vim: set ft=markdown tw=72:
title: CGO passing a function pointer to C
date: 2024-11-04T15:23:59-0700
lastmod: 2025-04-14T15:59:37-0600
draft: false
publish: true
aliases: [/notes/3zy23um5/]
tags: [golang, code-snippet]
---

By default when passing a function as an argument, Cgo uses
unsafe.Pointer. This will result in an
[IncompatibleAssign error][assign-error].

In order to pass a function pointer as an argument to a C function, type
conversion must be used. In the example below `(*[0]byte)` is used to
convert `C.print_hello` to what `C.invoke` expects. `(*[0]byte)` is
special, it means the same as [`void *` in `C`][cgo-go-callback].

```go
package main

/*
#include <stdio.h>

static void invoke(void (*f)()) {
	f();
}

void print_hello() {
	printf("Hello, World!\n");
}
*/
import "C"

func main() {
	C.invoke((*[0]byte)(C.print_hello))
}
```

## Other workarounds

Use `typedef` and explicitly convert to the type:

```go
package main

/*
#include <stdio.h>

typedef void (*PrintHelloFn)();

static void invoke(void (*f)()) {
	f();
}

void printHello() {
	printf("Hello, World from C!\n");
}
*/
import "C"

func main() {
	C.invoke(C.PrintHelloFn(C.printHello))
}
```

## Useful links

[IBM - CGO callbacks](https://community.ibm.com/community/user/ibmz-and-linuxone/blogs/dustin-ward/2024/02/12/cgo-callbacks-on-zos?communityKey=6fb961a9-1e24-42c4-ad73-6a4a6b799f8a)
[Passing callbacks and pointers to CGO](https://eli.thegreenplace.net/2019/passing-callbacks-and-pointers-to-cgo/)
[Passing pointers](https://pkg.go.dev/cmd/cgo#hdr-Passing_pointers)
[CGO wiki](https://go.dev/wiki/cgo)

[assign-error]: https://github.com/golang/go/issues/19835
[cgo-go-callback]: https://groups.google.com/g/golang-nuts/c/VzOkHPO4Y6o/m/GGJQ9MQodSAJ
