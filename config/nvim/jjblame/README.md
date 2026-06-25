# jjblame

A scroll-bound [Jujutsu](https://github.com/jj-vcs/jj) `file annotate` blame
panel for Neovim. Commit diffs open in splits, never a new tab.

`<leader>gb` (or `require("jjblame").toggle()`) opens a left panel beside the
file, scroll-bound to the source window. Consecutive lines that share a
change-id are condensed into a single run: the change-id/author/date label is
shown once on the run's first line, each run is wrapped by a bracket glyph
(`╭ │ ╰`, or `╶` for a single line), and the bracket plus change-id are tinted
by a per-change-id color so the same commit is the same color everywhere. The
annotation snapshots the working copy (no `--ignore-working-copy`) so the blame
lines up exactly with the buffer.

## Requirements

- `jj` on your `PATH`
- Neovim >= 0.10 (for `vim.system`)

## Install

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "you/jjblame.nvim",
  keys = {
    { "<leader>gb", function() require("jjblame").toggle() end, desc = "JJ blame" },
  },
}
```

## Configuration

`setup()` accepts overrides for the bracket glyphs and the color palette:

```lua
require("jjblame").setup({
  glyphs = {
    top = "╭",
    mid = "│",
    bot = "╰",
    single = "╶",
  },
  -- base46 base_30 key names (resolved live from the active theme) or "#rrggbb":
  palette = {
    "blue",
    "green",
    "purple",
    "cyan",
    "yellow",
    "orange",
    "teal",
    "red",
    "pink",
    "nord_blue",
  },
})
```

Colors are resolved from the active [base46](https://github.com/NvChad/base46)
theme when available (so they track theme toggles), falling back to bundled
onedark hexes otherwise. A change-id hashes to a stable palette slot; touching
runs that would collide are nudged to the next color.

## Mappings

Inside the blame panel:

- `<CR>` — open the line's commit diff in a vertical split
- `<C-x>` — open the line's commit diff in a horizontal split
- `q` — close the blame panel

Inside an opened commit diff:

- `q` — close the diff split

## API

- `require("jjblame").toggle()` — toggle the blame panel for the current buffer.
- `require("jjblame").close(src)` — close the blame panel for source buffer `src`.

## Layout

```
lua/jjblame/
  init.lua   public API: setup/toggle/close
  config.lua defaults (glyphs, palette) + merge(opts)
  jj.lua     sys runner + repo resolution + annotate template
  panel.lua  build/teardown the scroll-bound blame panel
  colors.lua palette resolution + per-change-id section highlights
  diff.lua   open a commit's diff for a blame line in a split
  util.lua   user notifications
plugin/jjblame.lua  load guard
doc/jjblame.txt     :help jjblame
```
