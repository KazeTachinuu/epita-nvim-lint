# epita-nvim-lint

[nvim-lint](https://github.com/mfussenegger/nvim-lint) integration for [epita-coding-style](https://pypi.org/project/epita-coding-style/), the EPITA C/C++ coding style checker.

Provides inline diagnostics in Neovim for EPITA coding style violations.

## Requirements

- Neovim >= 0.10
- [nvim-lint](https://github.com/mfussenegger/nvim-lint)
- [epita-coding-style](https://pypi.org/project/epita-coding-style/)

## Install epita-coding-style

```sh
pipx install epita-coding-style
```

## Install the plugin

### [lazy.nvim](https://github.com/folke/lazy.nvim) / [LazyVim](https://www.lazyvim.org/)

Add to your `lua/plugins/` directory (e.g. `lua/plugins/epita-lint.lua`):

```lua
return {
  { import = "epita-nvim-lint" },
}
```

## Configuration

The linter respects your project's `epita-style.toml` / `.epita-style` config file. See `epita-coding-style --help` for options.

## License

MIT
