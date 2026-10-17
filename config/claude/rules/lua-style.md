---
paths:
  - "**/*.lua"
---

## Style Rules — Newlines

### Return statements

A blank line **must** precede every `return`, **unless** it is the only statement in the scope.

### Control flow statements

`if`, `for`, `while`, and `repeat` blocks **must** have a blank line before and after them when adjacent to assignments, function calls, or other non-control-flow statements.

### Nested control flow

When control flow is nested directly inside other control flow with **no** surrounding statements, **no** blank lines are added between them.

### Declarations vs. actions

Declarations (`local` bindings, assignments) and actions (standalone function calls, method calls) are discrete kinds of intent. A blank line **must** separate a group of declarations from a group of actions, and vice versa. Consecutive statements of the same kind **may** be grouped together without blank lines between them.

### Example exercising all rules

```lua
-- Return as only statement in scope — no blank line needed.
local function trivial()
  return 42
end

-- Return preceded by a statement — blank line required.
local function computed(x)
  local result = x * 2

  return result
end

-- Early return with preceding work — blank line required.
local function early_and_final(x)
  local base = x + 1

  if base > 10 then
    return base
  end

  local adjusted = base * 3

  return adjusted
end

-- Control flow between statements — blank line before and after.
local function process(items)
  local total = 0

  for _, item in ipairs(items) do
    total = total + item
  end

  local factor = 2

  if total > 100 then
    total = 100
  end

  return total * factor
end

-- Nested control flow with no surrounding statements — no blank lines.
local function nested_only(x)
  if x ~= nil then
    if x.inner ~= nil then
      if x.inner == 0 then
        return -1
      else
        return x.inner
      end
    else
      return 0
    end
  else
    return 0
  end
end

-- Declarations and actions separated — blank lines between groups.
local function build_and_verify()
  local items = {}

  table.insert(items, 1)
  table.insert(items, 2)
  table.insert(items, 3)

  local count = #items
  local expected = 3

  assert(count == expected)
  assert(count > 0)

  do_something(items)
end

-- Mix: nested control flow plus statements around it.
local function mixed(data, threshold)
  local out = {}

  for _, item in ipairs(data) do
    if item ~= nil then
      if item > threshold then
        table.insert(out, item)
      end
    end
  end

  return out
end
```
