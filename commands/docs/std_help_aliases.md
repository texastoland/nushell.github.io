---
title: std help aliases
categories: |
  default
version: 0.91.0
default: |
  Show help on nushell aliases.
usage: |
  Show help on nushell aliases.
feature: default
---
<!-- This file is automatically generated. Please edit the command in https://github.com/nushell/nushell instead. -->

# `{{ $frontmatter.title }}` for [default](/commands/categories/default.md)

<div class='command-title'>{{ $frontmatter.default }}</div>


::: warning
The standard library is in alpha development stage. You can find more documentation on [GitHib](https://github.com/nushell/nushell/tree/main/crates/nu-std).
:::
## Signature

```> std help aliases {flags} ...rest```

## Flags

 -  `--find, -f {string}`: string to find in alias names

## Parameters

 -  `...rest`: the name of alias to get help on


## Input/output types:

| input | output |
| ----- | ------ |
| any   | any    |

## Notes
Examples:
    > let us define a bunch of aliases
    > ```nushell
    > # my foo alias
    > alias foo = echo "this is foo"
    >
    > # my bar alias
    > alias bar = echo "this is bar"
    >
    > # my baz alias
    > alias baz = echo "this is baz"
    >
    > # a multiline alias
    > alias multi = echo "this
    > is
    > a
    > multiline
    > string"
    > ```

    show all aliases
    > help aliases
    ╭───┬───────┬────────────────────┬───────────────────╮
    │ # │ name  │     expansion      │       usage       │
    ├───┼───────┼────────────────────┼───────────────────┤
    │ 0 │ bar   │ echo "this is bar" │ my bar alias      │
    │ 1 │ baz   │ echo "this is baz" │ my baz alias      │
    │ 2 │ foo   │ echo "this is foo" │ my foo alias      │
    │ 3 │ multi │ echo "this         │ a multiline alias │
    │   │       │ is                 │                   │
    │   │       │ a                  │                   │
    │   │       │ multiline          │                   │
    │   │       │ string"            │                   │
    ╰───┴───────┴────────────────────┴───────────────────╯

    search for string in alias names
    > help aliases --find ba
    ╭───┬──────┬────────────────────┬──────────────╮
    │ # │ name │     expansion      │    usage     │
    ├───┼──────┼────────────────────┼──────────────┤
    │ 0 │ bar  │ echo "this is bar" │ my bar alias │
    │ 1 │ baz  │ echo "this is baz" │ my baz alias │
    ╰───┴──────┴────────────────────┴──────────────╯

    search help for single alias
    > help aliases multi
    a multiline alias

    Alias: multi

    Expansion:
      echo "this
    is
    a
    multiline
    string"

    search for an alias that does not exist
    > help aliases "does not exist"
    Error:
      × std::help::alias_not_found
       ╭─[entry #21:1:1]
     1 │ help aliases "does not exist"
       ·              ────────┬───────
       ·                      ╰── alias not found
       ╰────