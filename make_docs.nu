# bring the standard library preview module into scope
use std

# get all command names from a clean scope
# ideally we'd select everything but
# dataframes in examples.result don't serialize
# NUON is slow anyway and JSON is lossy
def command-names [] {
  nu --no-config-file --commands '
  use std
  scope commands | select name
  | to json' | from json
}

# remove invalid characters from a path
#
# # Examples
# using the standard library
# ```nushell
# use std.nu
#
# std assert eq ("foo/bar baz/foooo" | safe-path) "foo/bar_baz/foooo"
# std assert eq ("invalid ? path" | safe-path) "invalid__path"
# ```
def safe-path [] {
  $in | str replace --all '\?' '' | str replace --all ' ' '_'
}

# generate the YAML frontmatter of a command
#
# # Examples
# - the `bits` command in `commands/docs/bits.md`
# ```yaml
# ---
# title: bits
# categories: |
#   bits
# version: 0.76.1
# bits: |
#   Various commands for working with bits.
# usage: |
#   Various commands for working with bits.
# ---
# ```
# - the `dfr min` command in `commands/docs/dfr_min.md`
# ```yaml
# ---
# title: dfr min
# categories: |
#   expression
#   lazyframe
# version: 0.76.0
# expression: |
#   Creates a min expression
# lazyframe: |
#   Aggregates columns to their min value
# usage: |
#   Creates a min expression
#   Aggregates columns to their min value
# ---
# ```
def command-frontmatter [command] {
    let category_list = ($command.category | str join $"(char newline)  " )
    let nu_version = (version).version
    let indented_usage = (
        $command.usage
        | lines
        | each {|it| $"  ($it)"}
        | str join (char newline)
    )
    let category_matter = (
        $command.category
        | each { |category|
            $'($category | str snake-case): |(char newline)($indented_usage)'
        }
        | str join (char newline)
    )

    let feature = if $command.name starts-with dfr {
        "dataframe"
    } else {
        "default"
    }

  # This is going in the frontmatter as a multiline YAML string, so indentation matters
$"---
title: ($command.name)
categories: |
  ($category_list)
version: ($nu_version)
($category_matter)
usage: |
($indented_usage)
feature: ($feature)
---"
}


# generate the whole command documentation
#
# TODO: be more detailed here
def command-doc [command] {
    let top = $"
# `{{ $frontmatter.title }}` for [($command.category)]\(/commands/categories/($command.category).md\)

<div class='command-title'>{{ $frontmatter.($command.category | str snake-case) }}</div>

"

    let columns = ($command.signatures | columns)
    let no_sig = ($command.signatures | is-empty)
    let sig = if $no_sig { '' } else {
        ($command.signatures | get $columns.0 | each { |param|
            if $param.parameter_type == "positional" {
                $"('(')($param.parameter_name)(')')"
            } else if $param.parameter_type == "rest" {
                $"...rest"
            }
        } | str join " ")
    }

    let signatures = $"## Signature

```> ($command.name) {flags} ($sig)```

"
    let flag_types = ['named', 'switch']
    let no_flags = if $no_sig { true } else {
        $command.signatures | get $columns.0 | where parameter_type in $flag_types | is-empty
    }

    let flags = if $no_flags { '' } else {
        ($command.signatures | get $columns.0 | each { |param|
            if $param.parameter_type == "switch" {
                $" -  `--($param.parameter_name), -($param.short_flag)`: ($param.description)"
            } else if $param.parameter_type == "named" {
                $" -  `--($param.parameter_name), -($param.short_flag) {($param.syntax_shape)}`: ($param.description)"
            }
        } | str join (char newline))
    }

    let flags = if $no_flags { "" } else {
$"## Flags

($flags)

"
    }

    let param_types = ['rest', 'positional']
    let no_param = if $no_sig { true } else {
        $command.signatures | get $columns.0 | where parameter_type in $param_types | is-empty
    }

    let params = if $no_param { '' } else {
        ($command.signatures | get $columns.0 | each { |param|
            if $param.parameter_type == "positional" {
                $" -  `($param.parameter_name)`: ($param.description)"
            } else if $param.parameter_type == "rest" {
                $" -  `...rest`: ($param.description)"
            }
        } | str join (char newline))
    }

    let parameters = if $no_param { "" } else {
$"## Parameters

($params)

"
    }

    let ex = $command.extra_usage

    # Certain commands' extra_usage is wrapped in code block markup to prevent their code from
    # being interpreted as markdown. This is strictly hard-coded for now.
    let extra_usage = if $ex == "" {
        ""
    } else if $command.name in ['def-env' 'export def-env' 'as-date' 'as-datetime' ansi] {
$"## Notes
```text
($ex)
```
"
    } else {
$"## Notes
($ex)
"
    }

    let sigs = scope commands | where name == $command.name | select signatures | first | get signatures | values
    mut input_output = []
    for s in $sigs {
        let input = $s | where parameter_type == 'input' | first | get syntax_shape
        let output = $s | where parameter_type == 'output' | first | get syntax_shape
        # FIXME: Parentheses are required here to mutate $input_output, otherwise it won't work, maybe a bug?
        $input_output = ($input_output | append [[input output]; [$input $output]])
    }
    let in_out = if ($input_output | length) > 0 {
        let markdown = ($input_output | sort-by input | to md --pretty | str replace -a '<' '\<' | str replace -a '>' '\>')
        ['', '## Input/output types:', '', $markdown, ''] | str join (char newline)
    } else { '' }

    let examples = if ($command.examples | length) > 0 {
        let example_top = $"## Examples(char newline)(char newline)"

        let $examples = (
            $command.examples
            | each { |example|
                let result = (do -i { $example.result | try { table --expand } catch { $in } } )
$"($example.description)
```nu
> ($example.example)
($result | if ($result | describe) == "string" { ansi strip } else { $in })
```

"
            } | str join
        )

        $example_top + $examples
    } else {
        ""
    }

    # Typically a root command that has sub commands should be one word command
    let one_word_cmd = ($command.name | split row ' ' | length) == 1
    let sub_commands = if $one_word_cmd { scope commands | where name =~ $'^($command.name) ' } else { [] }
    let type_mapping = {is_builtin: 'Builtin', is_plugin: 'Plugin', is_custom: 'Custom'}
    let sub_commands = if $one_word_cmd and ($sub_commands | length) > 0 {
        let commands = $sub_commands
            | select name usage is_builtin is_plugin is_custom
            | update name {|it| $"[`($it.name)`]\(/commands/docs/($it.name | safe-path).md\)" }
            | upsert usage {|it| $it.usage | str replace -a '<' '\<' | str replace -a '>' '\>' }
            | upsert type {|it| $type_mapping | columns | each {|t| if ($it | get $t) { $type_mapping | get $t } } | str join ',' }
            | select name type usage
            | to md --pretty
        ['', '## Subcommands:', '', $commands, ''] | str join (char newline)
    } else { '' }

    let warning = if $command.name starts-with std {
        'The standard library is in alpha development stage. You can find more documentation on [GitHib](https://github.com/nushell/nushell/tree/main/crates/nu-std).'
    } else if $command.name starts-with dfr {
        'Dataframe commands were not shipped in the official binaries by default, you have to build it with `--features=dataframe` flag'
    } else if $command.name in ['from ini', 'from ics', 'from eml', 'from vcf'] {
        $"Command `($command.name)` resides in [plugin]\(/book/plugins.html) [`nu_plugin_formats`]\(https://crates.io/crates/nu_plugin_formats). To use this command, you must install/compile and register nu_plugin_formats"
    }
    let warning = if $warning == null {
        ''
    } else {
        $"\n::: warning\n($warning)\n:::\n"
    }

    let doc = (
        ($top + $warning + $signatures + $flags + $parameters + $in_out + $examples + $extra_usage + $sub_commands)
        | lines
        | each {|it| ($it | str trim -r) }
        | str join (char newline)
    )

    $doc
}


# generate the full documentation page of a given command
#
# this command will
# 1. compute the frontmatter of the command, i.e. the YAML header
# 2. compute the actual content of the documentation
# 3. concatenate them
# 4. save that to `commands/docs/<command>.md`
#
# # Examples
# - the `bits` command at https://nushell.sh/commands/docs/bits.html
# - the `bits and` subcommand at https://nushell.sh/commands/docs/bits_and.html
def generate-command [command] {
    let safe_name = ($command.name | safe-path)
    let doc_path = (['.', 'commands', 'docs', $'($safe_name).md'] | path join)

    let frontmatter = (command-frontmatter $command)
    let note = "<!-- This file is automatically generated. Please edit the command in https://github.com/nushell/nushell instead. -->"
    let doc = (command-doc $command)

    [$frontmatter $note $doc] | str join "\n" | save --raw --force $doc_path
    $doc_path
}


# generate the list of all categories in a TS file used by `vuepress`
#
# this will modify `.vuepress/configs/sidebar/command_categories.ts`
#
# # Example
# the sidebar file has following format
# ```typescript
# export const commandCategories = [
#   '/commands/categories/<categ_1>.md',
#   '/commands/categories/<categ_2>.md',
#   ...
# ];
# ```
# and contains all the categories given by `$nu.scope.commands.category | uniq`
#
# this file is responsible for the sidebar containing the categories that one can see in
#
#    https://nushell.sh/commands/
def generate-category-sidebar [unique_categories --hide = []] {
    let sidebar_path = (['.', '.vuepress', 'configs', "sidebar", "command_categories.ts"] | path join)
    let list_content = (
      $unique_categories | where $it not-in $hide
        | each { || safe-path }
        | each { |category| $"  '/commands/categories/($category).md',"}
        | str join (char newline)
    )

$"export const commandCategories = [
($list_content)
];"
    | save --raw --force $sidebar_path
}


# generate one category file in `commands/categories/`
#
# # Example
# for the `bits` category, that might look, once rendered, like
#
#    https://nushell.sh/commands/categories/bits.html
def generate-category [category] {
    let safe_name = ($category | safe-path)
    let doc_path = (['.', 'commands', 'categories', $'($safe_name).md'] | path join)

$"# ($category | str title-case)

<script>
  import pages from '@temp/pages'
  export default {
    computed: {
      commands\(\) {
        return pages
          .filter\(p => p.path.includes\('/commands/docs/'\)\)
          .filter\(p => p.frontmatter.categories.includes\('($category)'\)\)
          .sort\(\(a,b\) => \(a.title > b.title\) ? 1 : \(\(b.title > a.title\) ? -1 : 0\)\);
      }
    }
  }
</script>

<table>
  <tr>
    <th>Command</th>
    <th>Description</th>
  </tr>
  <tr v-for=\"command in commands\">
   <td><a :href=\"command.path\">{{ command.title }}</a></td>
   <td style=\"white-space: pre-wrap;\">{{ command.frontmatter.usage }}</td>
  </tr>
</table>
"
    | save --raw --force $doc_path

    $doc_path
}


def main [] {
    # Old commands are currently not deleted because some of them
    # are platform-specific (currently `exec`, `registry query`), and a single run of this script will not regenerate
    # all of them.
    #do -i { rm commands/docs/*.md }

    let unique_commands = (
        scope commands
        | join (command-names) name
        | sort-by category
    )
    let unique_categories = ($unique_commands.category | uniq)

    let number_generated_commands = (
        $unique_commands
        | par-each { |command|
            generate-command $command
        }
        | length
    )
    print $"($number_generated_commands) commands written"

    generate-category-sidebar --hide [default] $unique_categories

    let number_generated_categories = (
        $unique_categories
        | each { |category|
            generate-category $category
        }
        | length
    )
    print $"($number_generated_categories) categories written"
}
