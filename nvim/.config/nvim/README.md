# Neovim

## Astro projects with Deno

The config uses Astro's language server for `.astro` components and Deno's
language server for standalone JavaScript/TypeScript files in projects with a
`deno.json` or `deno.jsonc`. Deno's language server does not replace Astro's
component tooling. `ts_ls` stays disabled in Deno projects.

Install the editor dependencies in your Astro project:

```sh
deno add --dev npm:@astrojs/language-server npm:typescript@~6 npm:prettier npm:prettier-plugin-astro
```

Merge this setting into the project's `deno.json` so the Astro language server
and Prettier can find local executables and the TypeScript SDK:

```json
{
  "nodeModulesDir": "auto"
}
```

Then run `deno install`. TypeScript is pinned to 6.x because the Astro server's
SDK lookup requires `tsserverlibrary.js`, which TypeScript 7 removed.

Merge these options into the project's Prettier configuration (`.prettierrc`):

```json
{
  "plugins": ["prettier-plugin-astro"],
  "overrides": [
    {
      "files": "*.astro",
      "options": { "parser": "astro" }
    }
  ]
}
```

If you also use `prettier-plugin-tailwindcss`, keep it last in the plugins list.
Astro files format on save unless autoformat is disabled.

Tree-sitter installs Astro and its embedded-language parsers automatically.
Emmet is enabled for Astro buffers, but `emmet-language-server` must be on
Neovim's PATH. It comes from `@olrtg/emmet-language-server`, not `emmet-ls`.
The Tailwind language server is not enabled.

Restart Neovim after installing the dependencies. Use `:checkhealth vim.lsp` and
`:ConformInfo` to inspect language-server and formatter availability.
