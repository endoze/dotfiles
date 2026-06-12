-- Pure conversions from vim.diff index hunks to jjsigns signs and line counts.

local M = {}

--- Convert vim.diff index hunks {start_a, count_a, start_b, count_b} to signs.
function M.hunks_to_signs(hunks)
  local signs = {}

  for _, h in ipairs(hunks) do
    local count_a, start_b, count_b = h[2], h[3], h[4]

    if count_a == 0 then
      for l = start_b, start_b + count_b - 1 do
        signs[#signs + 1] = { line = l, type = "add" }
      end
    elseif count_b == 0 then
      if start_b == 0 then
        signs[#signs + 1] = { line = 1, type = "topdelete" }
      else
        signs[#signs + 1] = { line = start_b, type = "delete" }
      end
    else
      local t = count_a > count_b and "changedelete" or "change"

      for l = start_b, start_b + count_b - 1 do
        signs[#signs + 1] = { line = l, type = t }
      end
    end
  end

  return signs
end

--- Aggregate vim.diff hunks into {added, modified, removed} line counts.
function M.hunks_to_counts(hunks)
  local added, modified, removed = 0, 0, 0

  for _, h in ipairs(hunks) do
    local count_a, count_b = h[2], h[4]

    if count_a == 0 then
      added = added + count_b
    elseif count_b == 0 then
      removed = removed + count_a
    else
      local m = math.min(count_a, count_b)
      modified = modified + m
      added = added + (count_b - m)
      removed = removed + (count_a - m)
    end
  end

  return { added = added, modified = modified, removed = removed }
end

return M
