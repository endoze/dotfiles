import { test } from "node:test";
import assert from "node:assert/strict";
import { buildRows, type Question } from "./rows.ts";

const q = (over: Partial<Question> = {}): Question => ({
  id: "q1",
  prompt: "Pick one",
  label: "Q1",
  options: [
    { value: "a", label: "Alpha" },
    { value: "b", label: "Beta" },
  ],
  multiple: false,
  allowOther: false,
  ...over,
});

test("single-select single question: options then chat, no terminal row", () => {
  const rows = buildRows(q(), true, true);
  assert.deepEqual(
    rows.map((r) => r.kind),
    ["option", "option", "chat"],
  );
  assert.equal(rows[2].kind === "chat" && rows[2].number, 3);
});

test("allowOther inserts Type something and pushes chat up a number", () => {
  const rows = buildRows(q({ allowOther: true }), true, true);
  assert.deepEqual(
    rows.map((r) => r.kind),
    ["option", "option", "other", "chat"],
  );
  assert.equal(rows[2].kind === "other" && rows[2].number, 3);
  assert.equal(rows[3].kind === "chat" && rows[3].number, 4);
});

test("multi-select single question gets an unnumbered Submit", () => {
  const rows = buildRows(q({ multiple: true }), true, true);
  assert.deepEqual(
    rows.map((r) => r.kind),
    ["option", "option", "submit", "chat"],
  );
  assert.equal(rows[3].kind === "chat" && rows[3].number, 3);
});

test("multi-question call gets an unnumbered Next", () => {
  const rows = buildRows(q(), false, false);
  assert.deepEqual(
    rows.map((r) => r.kind),
    ["option", "option", "next", "chat"],
  );
});

test("options carry their own zero-based index and one-based number", () => {
  const rows = buildRows(q(), true, true);
  assert.equal(rows[0].kind === "option" && rows[0].index, 0);
  assert.equal(rows[0].kind === "option" && rows[0].number, 1);
  assert.equal(rows[1].kind === "option" && rows[1].number, 2);
});
