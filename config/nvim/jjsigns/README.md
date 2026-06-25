# jjsigns

gitsigns-style diff signs for [Jujutsu](https://github.com/jj-vcs/jj),
snapshot-free.

The base content is read from `@-` with `--ignore-working-copy`, so jj never
snapshots the working copy and there is zero oplog churn. The live buffer is
diffed against that base in-memory with `vim.diff`, so signs update as you type
and the plugin never shells out per keystroke.

## Requirements

- `jj` on your `PATH`
- Neovim >= 0.10 (for `vim.uv` and `vim.system`)

## Install

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "you/jjsigns.nvim",
  event = "User FilePost",
  config = function()
    require("jjsigns").setup({})
  end,
}
```

## Configuration

`setup()` accepts a table merged over the defaults:

```lua
require("jjsigns").setup({
  signs = {
    add = { text = "┃" },
    change = { text = "┃" },
    delete = { text = "󰍵" },
    topdelete = { text = "▔" },
    changedelete = { text = "󱕖" },
  },
  base = "@-",      -- revision diffed against
  debounce = 100,   -- ms between an edit and recompute
  priority = 6,     -- sign priority
})
```

Highlight groups `JJSignsAdd`, `JJSignsChange`, and `JJSignsDelete` are derived
from the colorscheme (preferring `Added`/`Changed`/`Removed`, then the diff-mode
groups) and refreshed on `ColorScheme`.

## Commands

- `:JJSignsRefresh` — re-fetch the base for every attached buffer.
- `:JJSignsToggle` — toggle signs on/off across all buffers.

## Statusline integration

`require("jjsigns").status_dict(bufnr)` returns `{ added, modified, removed }`
line counts for `bufnr` (default: current buffer), or `nil` when the buffer
isn't attached. The counts come from the same in-memory diff that places the
signs, so reading them is free:

```lua
local function jjsigns_diff()
  local d = require("jjsigns").status_dict()

  if not d then
    return ""
  end

  return string.format("+%d ~%d -%d", d.added, d.modified, d.removed)
end
```

## Layout

```
lua/jjsigns/
  init.lua        public API: setup/refresh/toggle/status_dict + autocmds
  config.lua      defaults + highlight-group map
  highlights.lua  resolve the JJSigns* highlight groups
  jj.lua          read-only jj command runner
  diff.lua        pure hunk -> signs / counts conversions
  signs.lua       extmark placement
  buffer.lua      per-buffer attach/detach + diffing lifecycle
plugin/jjsigns.lua  load guard
doc/jjsigns.txt     :help jjsigns
```
