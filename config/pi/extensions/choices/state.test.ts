import { test } from "node:test";
import assert from "node:assert/strict";
import {
  closeFreeform,
  createState,
  handleKey,
  isAnswered,
  rowsFor,
  submitFreeform,
  type Keypress,
} from "./state.ts";
import type { Question } from "./rows.ts";

const single = (over: Partial<Question> = {}): Question[] => [
  {
    id: "policy",
    prompt: "Pick one",
    label: "Policy",
    options: [
      { value: "lru", label: "LRU" },
      { value: "lfu", label: "LFU" },
    ],
    multiple: false,
    allowOther: false,
    ...over,
  },
];

const key = (name: Keypress["name"], digit?: number): Keypress => ({ name, digit });

const press = (questions: Question[], keys: Keypress[]) => {
  let state = createState(questions);
  for (const k of keys) {
    const result = handleKey(state, k);
    if ("done" in result) return { done: result.done, state };
    state = result.state;
  }
  return { done: null, state };
};

test("enter on a single-select option completes with that value", () => {
  const { done } = press(single(), [key("down"), key("enter")]);
  assert.equal(done?.kind, "completed");
  assert.deepEqual(done?.kind === "completed" && done.answers, [
    { id: "policy", values: ["lfu"], wasCustom: false },
  ]);
});

test("focus clamps at both ends", () => {
  const { state: top } = press(single(), [key("up"), key("up")]);
  assert.equal(top.focus, 0);
  const { state: bottom } = press(single(), [key("down"), key("down"), key("down"), key("down")]);
  // options, then chat: 3 rows, last index 2
  assert.equal(bottom.focus, 2);
});

test("space toggles in multi-select and does nothing in single-select", () => {
  const { state: multi } = press(single({ multiple: true }), [key("space")]);
  assert.deepEqual([...(multi.selections.get("policy") ?? [])], ["lru"]);

  const { state: one } = press(single(), [key("space")]);
  assert.equal(one.selections.get("policy")?.size ?? 0, 0);
});

test("enter toggles rather than commits in multi-select", () => {
  const { done, state } = press(single({ multiple: true }), [key("enter")]);
  assert.equal(done, null);
  assert.deepEqual([...(state.selections.get("policy") ?? [])], ["lru"]);
});

test("multi-select submit row completes with every ticked value", () => {
  const { done } = press(single({ multiple: true }), [
    key("space"),
    key("down"),
    key("space"),
    key("down"),
    key("enter"),
  ]);
  assert.deepEqual(done?.kind === "completed" && done.answers, [
    { id: "policy", values: ["lru", "lfu"], wasCustom: false },
  ]);
});

test("digit jumps to the numbered row", () => {
  const { done } = press(single(), [key("digit", 2)]);
  assert.equal(done?.kind === "completed" && done.answers[0].values[0], "lfu");
});

test("escape cancels", () => {
  const { done } = press(single(), [key("escape")]);
  assert.equal(done?.kind, "cancelled");
});

test("chat row yields chat carrying answers so far", () => {
  const { done } = press(single(), [key("digit", 3)]);
  assert.equal(done?.kind, "chat");
  assert.equal(done?.kind === "chat" && done.questionId, "policy");
  assert.deepEqual(done?.kind === "chat" && done.answers, []);
});

const pair = (): Question[] => [
  {
    id: "policy",
    prompt: "Pick one",
    label: "Policy",
    options: [
      { value: "lru", label: "LRU" },
      { value: "lfu", label: "LFU" },
    ],
    multiple: false,
    allowOther: false,
  },
  {
    id: "caches",
    prompt: "Pick any",
    label: "Caches",
    options: [
      { value: "session", label: "Session" },
      { value: "api", label: "API" },
    ],
    multiple: true,
    allowOther: false,
  },
];

test("next advances to the following question", () => {
  const { state } = press(pair(), [key("down"), key("down"), key("enter")]);
  assert.equal(state.current, 1);
  assert.equal(state.focus, 0);
});

test("single-select in a batch records the answer and advances", () => {
  const { done, state } = press(pair(), [key("enter")]);
  assert.equal(done, null);
  assert.deepEqual([...(state.selections.get("policy") ?? [])], ["lru"]);
  assert.equal(state.current, 1);
  assert.equal(state.focus, 0);
});

test("answering the last single-select question opens review", () => {
  const questions = [pair()[0], { ...pair()[0], id: "second", label: "Second" }];
  const { state } = press(questions, [key("enter"), key("enter")]);
  assert.equal(state.review, true);
});

test("next on the last question opens review", () => {
  // Skip Q1 with Next, then Next again on the multi-select Q2.
  const { state } = press(pair(), [
    key("down"),
    key("down"),
    key("enter"),
    key("down"),
    key("down"),
    key("enter"),
  ]);
  assert.equal(state.review, true);
});

test("left from review returns to the last question", () => {
  const { state } = press(pair(), [
    key("enter"),
    key("down"),
    key("down"),
    key("enter"),
    key("left"),
  ]);
  assert.equal(state.review, false);
  assert.equal(state.current, 1);
});

test("left and right move between questions", () => {
  const { state: forward } = press(pair(), [key("right")]);
  assert.equal(forward.current, 1);

  const { state: back } = press(pair(), [key("right"), key("left")]);
  assert.equal(back.current, 0);

  // Left on the first question clamps rather than wrapping.
  const { state: clamped } = press(pair(), [key("left")]);
  assert.equal(clamped.current, 0);
});

test("right clamps at the last question rather than opening review", () => {
  const { state } = press(pair(), [key("right"), key("right"), key("right")]);
  assert.equal(state.current, 1);
  assert.equal(state.review, false);
});

test("submit answers from review completes", () => {
  // Q1 is single-select so Enter answers and advances. Q2 is multi-select:
  // Space ticks, then Next opens review.
  const { done } = press(pair(), [
    key("enter"),
    key("space"),
    key("down"),
    key("down"),
    key("enter"),
    key("digit", 1),
  ]);
  assert.equal(done?.kind, "completed");
  assert.deepEqual(done?.kind === "completed" && done.answers, [
    { id: "policy", values: ["lru"], wasCustom: false },
    { id: "caches", values: ["session"], wasCustom: false },
  ]);
});

test("review exposes only two rows, so the answer list is not focusable", () => {
  const toReview = [key("enter"), key("space"), key("down"), key("down"), key("enter")];

  const { state } = press(pair(), toReview);
  assert.equal(state.review, true);
  assert.equal(rowsFor(state).length, 2);

  // Arrowing down past the two rows clamps rather than reaching an answer.
  const { state: clamped } = press(pair(), [...toReview, key("down"), key("down"), key("down")]);
  assert.equal(clamped.focus, 1);

  // A digit beyond the two rows does nothing.
  const { done } = press(pair(), [...toReview, key("digit", 3)]);
  assert.equal(done, null);
});

test("isAnswered tracks each question independently", () => {
  const questions = pair();
  const { state } = press(questions, [key("enter")]);
  assert.equal(isAnswered(state, questions[0]), true);
  assert.equal(isAnswered(state, questions[1]), false);
});

test("isAnswered stays false while the editor is open", () => {
  const { state } = press(single({ allowOther: true }), [key("digit", 3)]);
  assert.equal(state.freeform, true);
  assert.equal(isAnswered(state, state.questions[0]), false);
});

test("cancel from review cancels", () => {
  const { done } = press(pair(), [
    key("enter"),
    key("down"),
    key("down"),
    key("enter"),
    key("digit", 2),
  ]);
  assert.equal(done?.kind, "cancelled");
});

test("the other row opens the editor", () => {
  const { state } = press(single({ allowOther: true }), [key("digit", 3)]);
  assert.equal(state.freeform, true);
});

test("keys are ignored while the editor owns input", () => {
  const { state } = press(single({ allowOther: true }), [
    key("digit", 3),
    key("down"),
    key("escape"),
    key("digit", 1),
  ]);
  // Still open, still on the same question: choices.ts routes these to Editor.
  assert.equal(state.freeform, true);
  assert.equal(state.focus, 2);
});

test("submitFreeform records the text and completes a single question", () => {
  const { state } = press(single({ allowOther: true }), [key("digit", 3)]);
  const result = submitFreeform(state, "  sliding window  ");

  assert.ok("done" in result);
  assert.deepEqual(result.done.kind === "completed" && result.done.answers, [
    { id: "policy", values: ["sliding window"], wasCustom: true },
  ]);
});

test("submitFreeform replaces a single-select option rather than joining it", () => {
  const questions = single({ allowOther: true });
  let state = createState(questions);

  // Tick an option first, then answer with text instead.
  const toggled = handleKey(state, key("space"));
  assert.ok("state" in toggled);
  const opened = handleKey(toggled.state, key("digit", 3));
  assert.ok("state" in opened);

  const result = submitFreeform(opened.state, "typed instead");
  assert.ok("done" in result);
  assert.deepEqual(result.done.kind === "completed" && result.done.answers, [
    { id: "policy", values: ["typed instead"], wasCustom: true },
  ]);
});

test("submitFreeform with empty text closes the editor without answering", () => {
  const { state } = press(single({ allowOther: true }), [key("digit", 3)]);
  const result = submitFreeform(state, "   ");

  assert.ok("state" in result);
  assert.equal(result.state.freeform, false);
  assert.equal(isAnswered(result.state, result.state.questions[0]), false);
});

test("closeFreeform leaves the editor without recording anything", () => {
  const { state } = press(single({ allowOther: true }), [key("digit", 3)]);
  const closed = closeFreeform(state);

  assert.equal(closed.freeform, false);
  assert.equal(isAnswered(closed, closed.questions[0]), false);
});

test("freeform in a batch advances to the next question", () => {
  const questions = [
    { ...pair()[0], allowOther: true },
    { ...pair()[1], id: "caches" },
  ];
  let state = createState(questions);

  const opened = handleKey(state, key("digit", 3));
  assert.ok("state" in opened);

  const result = submitFreeform(opened.state, "something else");
  assert.ok("state" in result);
  assert.equal(result.state.current, 1);
  assert.equal(result.state.freeform, false);
});
