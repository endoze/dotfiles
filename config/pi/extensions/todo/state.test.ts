import { test } from "node:test";
import assert from "node:assert/strict";
import {
  type BranchEntry,
  counts,
  MAX_TODOS,
  reconstruct,
  summarize,
  todosFrom,
  type Todo,
  validate,
} from "./state.ts";

function todo(content: string, status: Todo["status"] = "pending"): Todo {
  return { content, status, activeForm: `${content}ing` };
}

function resultEntry(todos: unknown, toolName = "todo_write"): BranchEntry {
  return {
    type: "message",
    message: { role: "toolResult", toolName, details: { todos } },
  };
}

test("validate accepts a well-formed list", () => {
  const result = validate([
    { content: "Add the widget", status: "in_progress", activeForm: "Adding the widget" },
    { content: "Write tests", status: "pending", activeForm: "Writing tests" },
  ]);

  assert.equal(result.ok, true);
  assert.equal(result.ok && result.todos.length, 2);
});

test("validate accepts an empty list as a clear", () => {
  const result = validate([]);

  assert.equal(result.ok, true);
  assert.deepEqual(result.ok && result.todos, []);
});

test("validate rejects more than one in_progress", () => {
  const result = validate([
    { content: "One", status: "in_progress", activeForm: "Doing one" },
    { content: "Two", status: "in_progress", activeForm: "Doing two" },
  ]);

  assert.equal(result.ok, false);
  assert.match(result.ok ? "" : result.error, /only one todo may be in_progress/);
});

test("validate allows zero in_progress", () => {
  const result = validate([
    { content: "One", status: "completed", activeForm: "Doing one" },
    { content: "Two", status: "pending", activeForm: "Doing two" },
  ]);

  assert.equal(result.ok, true);
});

test("validate rejects a non-array", () => {
  assert.equal(validate("nope").ok, false);
  assert.equal(validate(undefined).ok, false);
});

test("validate rejects empty or blank content and activeForm", () => {
  const blankContent = validate([{ content: "  ", status: "pending", activeForm: "Doing" }]);
  const blankActive = validate([{ content: "Do", status: "pending", activeForm: "" }]);

  assert.equal(blankContent.ok, false);
  assert.match(blankContent.ok ? "" : blankContent.error, /content/);
  assert.equal(blankActive.ok, false);
  assert.match(blankActive.ok ? "" : blankActive.error, /activeForm/);
});

test("validate rejects an unknown status", () => {
  const result = validate([{ content: "Do", status: "doing", activeForm: "Doing" }]);

  assert.equal(result.ok, false);
  assert.match(result.ok ? "" : result.error, /invalid status/);
});

test("validate reports the offending index in 1-based form", () => {
  const result = validate([
    { content: "Fine", status: "pending", activeForm: "Fining" },
    { content: "", status: "pending", activeForm: "Doing" },
  ]);

  assert.match(result.ok ? "" : result.error, /todo 2/);
});

test("validate trims surrounding whitespace", () => {
  const result = validate([{ content: "  Do it  ", status: "pending", activeForm: "  Doing  " }]);

  assert.equal(result.ok && result.todos[0].content, "Do it");
  assert.equal(result.ok && result.todos[0].activeForm, "Doing");
});

test("validate caps the list length", () => {
  const many = Array.from({ length: MAX_TODOS + 1 }, (_, i) => ({
    content: `Task ${i}`,
    status: "pending",
    activeForm: `Doing ${i}`,
  }));

  const result = validate(many);

  assert.equal(result.ok, false);
  assert.match(result.ok ? "" : result.error, /too many todos/);
});

test("reconstruct returns an empty list for an empty branch", () => {
  assert.deepEqual(reconstruct([], "todo_write"), []);
});

test("reconstruct takes the last write on the branch", () => {
  const entries: BranchEntry[] = [
    resultEntry([todo("First")]),
    resultEntry([todo("Second"), todo("Third")]),
  ];

  const todos = reconstruct(entries, "todo_write");

  assert.equal(todos.length, 2);
  assert.equal(todos[0].content, "Second");
});

test("reconstruct ignores other tools and non-message entries", () => {
  const entries: BranchEntry[] = [
    resultEntry([todo("Mine")]),
    resultEntry([todo("Theirs")], "some_other_tool"),
    { type: "model_change" },
    { type: "message", message: { role: "user" } },
  ];

  const todos = reconstruct(entries, "todo_write");

  assert.equal(todos.length, 1);
  assert.equal(todos[0].content, "Mine");
});

test("reconstruct keeps the prior list when a later result stored no details", () => {
  const entries: BranchEntry[] = [
    resultEntry([todo("Kept")]),
    { type: "message", message: { role: "toolResult", toolName: "todo_write" } },
  ];

  assert.equal(reconstruct(entries, "todo_write")[0].content, "Kept");
});

test("reconstruct honors an explicit clear", () => {
  const entries: BranchEntry[] = [resultEntry([todo("Gone")]), resultEntry([])];

  assert.deepEqual(reconstruct(entries, "todo_write"), []);
});

test("reconstruct keeps the prior list across a rejected call", () => {
  const entries: BranchEntry[] = [
    resultEntry([todo("Kept")]),
    { type: "message", message: { role: "toolResult", toolName: "todo_write", details: {} } },
  ];

  assert.equal(reconstruct(entries, "todo_write")[0].content, "Kept");
});

test("todosFrom reads the list off a successful result", () => {
  assert.deepEqual(todosFrom({ todos: [todo("Ship")] }), [todo("Ship")]);
});

test("todosFrom reads an explicit clear as a list, not an absence", () => {
  assert.deepEqual(todosFrom({ todos: [] }), []);
});

// pi records a thrown tool as an empty details object rather than no details
// at all, so truthiness is not enough to tell a stored list from a rejection.
test("todosFrom is absent for the empty details pi stores on a rejected call", () => {
  assert.equal(todosFrom({}), undefined);
});

test("todosFrom is absent when there are no details", () => {
  assert.equal(todosFrom(undefined), undefined);
  assert.equal(todosFrom(null), undefined);
});

test("todosFrom is absent when todos is not an array", () => {
  assert.equal(todosFrom({ todos: "Ship" }), undefined);
});

test("counts tallies statuses and finds the active item", () => {
  const result = counts([
    todo("Done", "completed"),
    todo("Now", "in_progress"),
    todo("Later"),
    todo("Also later"),
  ]);

  assert.equal(result.total, 4);
  assert.equal(result.completed, 1);
  assert.equal(result.pending, 2);
  assert.equal(result.active?.content, "Now");
});

test("counts reports no active item when nothing is in progress", () => {
  assert.equal(counts([todo("Later")]).active, undefined);
});

test("summarize reports a cleared list", () => {
  assert.match(summarize([]), /cleared/i);
});

test("summarize echoes the list with status marks", () => {
  const text = summarize([todo("Done", "completed"), todo("Now", "in_progress"), todo("Later")]);

  assert.match(text, /1\/3 completed/);
  assert.match(text, /\[x\] Done/);
  assert.match(text, /\[~\] Now/);
  assert.match(text, /\[ \] Later/);
});
