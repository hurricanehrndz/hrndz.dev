---
# vim: set ft=markdown tw=72:
title: Golang Table Testing
date: 2024-12-12T16:39:35-0700
lastmod: 2024-12-12T16:39:35-0700
draft: false
publish: true
aliases: [/notes/clzp0z42/]
tags: [golang]
---

Table testing in Go is similar to what regression testing is in other
languages. Table testing involves calling the same test with different
inputs to ensure all tests still pass.

For example:

```Go
type inputsType struct {
	a int
	b int
}

var testCases = []struct {
	inputs   inputsType
	expected int
}{
	{inputsType{2, 3}, 5},
	{inputsType{3, 3}, 6},
}

func TestAddTable(t *testing.T) {
	for i, tc := range testCases {
		t.Run(fmt.Sprintf("Test add case: %d", i), func(t *testing.T) {
			assert.Equal(t, tc.expected, add(tc.inputs.a, tc.inputs.b))
		})
	}
}
```

See full example [here][table-testing-ex].

[table-testing-ex]: https://github.com/hurricanehrndz/examples/tree/main/clzp0z42
