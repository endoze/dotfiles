-- One Dark fallback border colors for Hyprland. Seeded into ~/.cache/wallust on
-- first run (and whenever the cache file is absent) so hyprland.lua's dofile
-- always finds real colors; wallust overwrites this per wallpaper.
--
-- Without this, general.col.* is never set and Hyprland falls back to its own
-- built-in default, which is a plain white active border. The six stops mirror
-- what the template emits from color1..color6.

hl.config({
  general = {
    col = {
      active_border = {
        colors = {
          "rgb(e06c75)",
          "rgb(98c379)",
          "rgb(e5c07b)",
          "rgb(61afef)",
          "rgb(c678dd)",
          "rgb(56b6c2)",
        },
      },
      inactive_border = "rgba(323741ee)",
    },
  },
})
