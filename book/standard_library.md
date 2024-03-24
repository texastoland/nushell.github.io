# Standard library (preview)

::: warning
The standard library is in alpha development stage. You can find more documentation on
[GitHib](https://github.com/nushell/nushell/tree/main/crates/nu-std).
:::

<script>
  import pages from '@temp/pages'
  export default {
    computed: {
      commands() {
        return pages
          .filter(p => p.path.includes('/commands/docs/std'))
          .sort((a, b) => (a.title > b.title) ? 1 : ((b.title > a.title) ? -1 : 0));
      }
    }
  }
</script>

<table>
  <tr>
    <th>Command</th>
    <th>Description</th>
  </tr>
  <tr v-for="command in commands">
    <td><a :href="command.path">{{ command.title }}</a></td>
    <td style="white-space: pre-wrap;">{{ command.frontmatter.usage }}</td>
  </tr>
</table>
