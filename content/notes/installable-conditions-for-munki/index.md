---
# vim: set ft=markdown tw=72:
title: Installable conditions for Munki
date: 2024-11-15T13:12:45-0700
lastmod: 2024-11-15T13:12:45-0700
draft: false
publish: true
aliases: [/notes/mw5pwh7j/]
tags: [macOS, munki]
---

Installable conditions in a Munki PLIST use a syntax know as
["Predicate Format String"][apple-predicate-docs]. See below for a quick
reference:

## Comparison Operators

**=, ==** Equality test

**>=, =>** Greater than equal to test

**\<=, =\<** Less than equal to test

**>** Greater than test

**\<** Less than test

**!=, \<>** Not equal test

## Compound Operators

**AND, &&** Logical AND

**OR, ||** Logical OR

**NOT, !** Logical NOT

[apple-predicate-docs]: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Predicates/Articles/pSyntax.html
