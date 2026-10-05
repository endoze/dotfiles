---
paths:
  - "**/*.rs"
---

## Style Rules — Newlines

### Return statements

A blank line **must** precede every `return` (explicit or trailing expression), **unless** it is the only statement in the scope.

### Control flow statements

`if`, `match`, `for`, `while`, and `loop` blocks **must** have a blank line before and after them when adjacent to assignments, method calls, or other non-control-flow statements.

### Nested control flow

When control flow is nested directly inside other control flow with **no** surrounding statements, **no** blank lines are added between them.

### Declarations vs. actions

Declarations (`let` bindings, assignments) and actions (standalone function calls, method calls, macro invocations) are discrete kinds of intent. A blank line **must** separate a group of declarations from a group of actions, and vice versa. Consecutive statements of the same kind **may** be grouped together without blank lines between them.

### Example exercising all rules

```rust
// Return as only statement in scope — no blank line needed.
fn trivial() -> i32 {
  42
}

// Return preceded by a statement — blank line required.
fn computed(x: i32) -> i32 {
  let result = x * 2;

  result
}

// Explicit return with preceding work — blank line required.
fn early_and_final(x: i32) -> i32 {
  let base = x + 1;

  if base > 10 {
    return base;
  }

  let adjusted = base * 3;

  adjusted
}

// Control flow between statements — blank line before and after.
fn process(items: &[i32]) -> i32 {
  let mut total = 0;

  for item in items {
    total += item;
  }

  let factor = 2;

  if total > 100 {
    total = 100;
  }

  total * factor
}

// Nested control flow with no surrounding statements — no blank lines.
fn nested_only(x: Option<Option<i32>>) -> i32 {
  if let Some(inner) = x {
    if let Some(val) = inner {
      match val {
        0 => -1,
        v => v,
      }
    } else {
      0
    }
  } else {
    0
  }
}

// Declarations and actions separated — blank lines between groups.
fn build_and_verify() {
  let mut items = Vec::new();

  items.push(1);
  items.push(2);
  items.push(3);

  let total: i32 = items.iter().sum();
  let expected = 6;

  assert_eq!(total, expected);
  assert!(total > 0);

  do_something(&items);
}

// Mix: nested control flow plus statements around it.
fn mixed(data: &[Option<i32>]) -> Vec<i32> {
  let mut out = Vec::new();
  let threshold = 5;

  for item in data {
    if let Some(val) = item {
      if *val > threshold {
        out.push(*val);
      }
    }
  }

  out
}
```
