---
title: std iter zip-into-record
categories: |
  default
version: 0.91.0
default: |
  Zips two lists and returns a record with the first list as headers
usage: |
  Zips two lists and returns a record with the first list as headers
feature: default
---
<!-- This file is automatically generated. Please edit the command in https://github.com/nushell/nushell instead. -->

# `{{ $frontmatter.title }}` for [default](/commands/categories/default.md)

<div class='command-title'>{{ $frontmatter.default }}</div>


::: warning
The standard library is in alpha development stage. You can find more documentation on [GitHib](https://github.com/nushell/nushell/tree/main/crates/nu-std).
:::
## Signature

```> std iter zip-into-record {flags} (other)```

## Parameters

 -  `other`: the values to zip with


## Input/output types:

| input | output |
| ----- | ------ |
| any   | any    |

## Notes
# Example
```nu
use std ["assert equal" "iter iter zip-into-record"]

let res = (
    [1 2 3] | iter zip-into-record [2 3 4]
)

assert equal $res [
    [1 2 3];
    [2 3 4]
]
```