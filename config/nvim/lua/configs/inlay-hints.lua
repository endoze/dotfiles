return function()
  require("inlay-hints").setup({
    renderer = "inlay-hints/render/eol",
    eol = {
      right_align = false,

      parameter = {
        separator = ", ",
        format = function(hints)
          local adjusted_hint = hints:gsub(":", "")

          return string.format(" <- (%s)", adjusted_hint)
        end,
      },

      type = {
        separator = ", ",
        format = function(hints)
          local adjusted_hint = hints:gsub(": ", "")

          if string.find(adjusted_hint, ",") then
            adjusted_hint = "(" .. adjusted_hint .. ")"
          end

          return string.format(" => %s", adjusted_hint)
        end,
      },
    },
  })
end
