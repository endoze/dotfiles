import { test } from "node:test";
import assert from "node:assert/strict";
import {
  renderList,
  renderOverlay,
  renderWidget,
  widgetWindow,
  type RenderTheme,
} from "./render.ts";
import type { Todo } from "./state.ts";
import { visibleWidth } from "../lib/width.ts";

// Identity theme: renders return plain text, so assertions read as the user
// sees them rather than through escape sequences.
const plain: RenderTheme = {
  fg: (_color, text) => text,
  bold: (text) => text,
};

function todo(content: string, status: Todo["status"] = "pending"): Todo {
  return { content, status, activeForm: `${content}ing` };
}

const WIDTH = 60;

test("renderList reports an empty list", () => {
  assert.deepEqual(renderList([], WIDTH, plain), ["  No todos"]);
});

test("renderList heads with a completion count", () => {
  const lines = renderList([todo("A", "completed"), todo("B")], WIDTH, plain);

  assert.match(lines[0], /1\/2 completed/);
});

test("renderList marks each status distinctly", () => {
  const lines = renderList(
    [todo("Done", "completed"), todo("Now", "in_progress"), todo("Later")],
    WIDTH,
    plain,
  ).join("\n");

  assert.match(lines, /✓ Done/);
  assert.match(lines, /◐ Now/);
  assert.match(lines, /○ Later/);
});

test("renderList truncates a collapsed list and says how many are hidden", () => {
  const todos = Array.from({ length: 7 }, (_, i) => todo(`Task ${i + 1}`));
  const lines = renderList(todos, WIDTH, plain);

  assert.match(lines.at(-1) as string, /… 3 more/);
  assert.ok(!lines.join("\n").includes("Task 7"));
});

test("renderList expanded shows every item and no overflow note", () => {
  const todos = Array.from({ length: 7 }, (_, i) => todo(`Task ${i + 1}`));
  const lines = renderList(todos, WIDTH, plain, { expanded: true }).join("\n");

  assert.match(lines, /Task 7/);
  assert.ok(!lines.includes("more"));
});

test("renderList keeps every line within the width", () => {
  const todos = [todo("A ridiculously long task description that will not fit in the column")];

  for (const line of renderList(todos, 30, plain, { expanded: true })) {
    assert.ok(visibleWidth(line) <= 30, `line too wide: ${visibleWidth(line)}`);
  }
});

test("renderWidget is absent for an empty list", () => {
  assert.equal(renderWidget([], WIDTH, plain), undefined);
});

test("renderWidget is absent once everything is complete", () => {
  const todos = [todo("A", "completed"), todo("B", "completed")];

  assert.equal(renderWidget(todos, WIDTH, plain), undefined);
});

test("renderWidget shows the active item's activeForm and its position", () => {
  const todos = [todo("Done", "completed"), todo("Build", "in_progress"), todo("Ship")];
  const lines = renderWidget(todos, WIDTH, plain) as string[];

  assert.match(lines[0], /2\/3/);
  assert.match(lines.join("\n"), /◐ Building/);
});

test("renderWidget falls back to the first pending item when nothing is active", () => {
  const todos = [todo("Done", "completed"), todo("Ship")];
  const lines = renderWidget(todos, WIDTH, plain) as string[];

  assert.match(lines[0], /2\/2/);
  assert.match(lines.join("\n"), /○ Ship/);
  assert.ok(!lines.join("\n").includes("Next:"));
});
test("renderWidget keeps every line within the width", () => {
  const todos = list(12, 5).map((item) => ({
    ...item,
    content: `${item.content} with a great deal of additional descriptive text`,
  }));

  for (const line of renderWidget(todos, 30, plain) as string[]) {
    assert.ok(visibleWidth(line) <= 30, `widget too wide: ${visibleWidth(line)}`);
  }
});

// A list of `total` items with item `activeIndex` in progress, everything
// before it completed and everything after it pending. Content and activeForm
// differ in case ("Task 5" vs "Doing task 5") so a test can tell which of the
// two a row rendered.
function list(total: number, activeIndex: number): Todo[] {
  return Array.from({ length: total }, (_, i): Todo => ({
    content: `Task ${i + 1}`,
    status:
      i < activeIndex ? "completed" : i === activeIndex ? "in_progress" : "pending",
    activeForm: `Doing task ${i + 1}`,
  }));
}

test("widgetWindow centers on the in_progress item", () => {
  assert.deepEqual(widgetWindow(list(10, 4)), { current: 4, start: 3, end: 7 });
});

test("widgetWindow falls back to the first pending item", () => {
  const todos = [todo("Done", "completed"), todo("Ship"), todo("Later")];

  assert.deepEqual(widgetWindow(todos), { current: 1, start: 0, end: 3 });
});

test("widgetWindow clamps to the start of the list", () => {
  assert.deepEqual(widgetWindow(list(10, 0)), { current: 0, start: 0, end: 3 });
});

test("widgetWindow clamps to the end of the list", () => {
  assert.deepEqual(widgetWindow(list(10, 9)), { current: 9, start: 8, end: 10 });
});

test("widgetWindow is absent for an empty list", () => {
  assert.equal(widgetWindow([]), undefined);
});

test("widgetWindow is absent once everything is complete", () => {
  assert.equal(widgetWindow([todo("A", "completed"), todo("B", "completed")]), undefined);
});
test("renderWidget counts from one on a fresh list", () => {
  assert.match((renderWidget(list(5, 0), WIDTH, plain) as string[])[0], /1\/5/);
});

test("renderWidget shows one item back, the current one, and two ahead", () => {
  const body = (renderWidget(list(10, 4), WIDTH, plain) as string[]).join("\n");

  assert.match(body, /✓ Task 4/);
  assert.match(body, /◐ Doing task 5/);
  assert.match(body, /○ Task 6/);
  assert.match(body, /○ Task 7/);
  assert.ok(!body.includes("Task 3"), "showed an item before the window");
  assert.ok(!body.includes("Task 8"), "showed an item after the window");
});

test("renderWidget reports how many items are hidden on each side", () => {
  const lines = renderWidget(list(10, 4), WIDTH, plain) as string[];

  assert.match(lines[0], /5\/10 \u00b7 3 above/);
  assert.match(lines.at(-1) as string, /\u2026 3 below/);
});

test("renderWidget omits the hidden counts when nothing is hidden", () => {
  const lines = renderWidget(list(3, 1), WIDTH, plain) as string[];

  assert.equal(lines.length, 4);
  assert.equal(lines[0].trim(), "2/3");
  assert.ok(!lines.join("\n").includes("below"));
});

test("renderWidget shrinks at the head of the list", () => {
  const lines = renderWidget(list(10, 0), WIDTH, plain) as string[];

  assert.equal(lines.length, 5);
  assert.equal(lines[0].trim(), "1/10");
  assert.match(lines.at(-1) as string, /\u2026 7 below/);
});

test("renderWidget shrinks at the tail of the list", () => {
  const lines = renderWidget(list(10, 9), WIDTH, plain) as string[];

  assert.equal(lines.length, 3);
  assert.match(lines[0], /10\/10 \u00b7 8 above/);
  assert.match(lines.join("\n"), /◐ Doing task 10/);
});

test("renderWidget uses activeForm only for the in_progress item", () => {
  const body = (renderWidget(list(10, 4), WIDTH, plain) as string[]).join("\n");

  assert.match(body, /Doing task 5/);
  assert.ok(!body.includes("Doing task 4"), "used activeForm for a completed item");
  assert.ok(!body.includes("Doing task 6"), "used activeForm for a pending item");
});

test("renderWidget renders a stalled list from its content", () => {
  const todos = [todo("Done", "completed"), todo("Ship"), todo("Later")];
  const body = (renderWidget(todos, WIDTH, plain) as string[]).join("\n");

  assert.match(body, /○ Ship/);
  assert.ok(!body.includes("Shiping"), "used activeForm for an item nobody started");
});

test("renderOverlay frames the list and hints at dismissal", () => {
  const lines = renderOverlay([todo("A")], WIDTH, plain);

  assert.match(lines.join("\n"), /Todos/);
  assert.match(lines.join("\n"), /Escape to close/);
});

test("renderOverlay expands past the collapsed limit", () => {
  const todos = Array.from({ length: 7 }, (_, i) => todo(`Task ${i + 1}`));

  assert.match(renderOverlay(todos, WIDTH, plain).join("\n"), /Task 7/);
});

test("renderOverlay keeps every line within the width", () => {
  const todos = Array.from({ length: 3 }, (_, i) => todo(`Task number ${i + 1} with text`));

  for (const line of renderOverlay(todos, 24, plain)) {
    assert.ok(visibleWidth(line) <= 24, `line too wide: ${visibleWidth(line)}`);
  }
});
