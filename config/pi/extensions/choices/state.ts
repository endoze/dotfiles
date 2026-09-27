// The state machine. Pure on purpose: no terminal, no theme, no I/O, so the
// interesting behavior (focus, numbering, selection, terminal states) is
// testable without driving a real TUI.

import { buildRows, type Question, type Row } from "./rows.ts";

export interface Answer {
  id: string;
  values: string[];
  wasCustom: boolean;
}

export type Outcome =
  | { kind: "completed"; answers: Answer[] }
  | { kind: "chat"; answers: Answer[]; questionId: string }
  | { kind: "cancelled" };

export interface State {
  questions: Question[];
  current: number;
  focus: number;
  selections: Map<string, Set<string>>;
  custom: Map<string, string>;
  /**
   * Whether the freeform editor is open. The text lives in pi's Editor over in
   * choices.ts, not here: Editor is a stateful pi-tui component, and importing
   * pi-tui into this module would make it unloadable outside pi and take the
   * test suite with it.
   */
  freeform: boolean;
  review: boolean;
}

export interface Keypress {
  name: "up" | "down" | "left" | "right" | "enter" | "space" | "escape" | "digit";
  digit?: number;
}

// The two rows the review screen exposes. The answer list above them is output
// only: it is not in the row model, so it can never take focus or a digit.
export const REVIEW_ROWS: Row[] = [
  { kind: "submit-answers", number: 1 },
  { kind: "cancel", number: 2 },
];

export function createState(questions: Question[]): State {
  return {
    questions,
    current: 0,
    focus: 0,
    selections: new Map(questions.map((q) => [q.id, new Set<string>()])),
    custom: new Map(),
    freeform: false,
    review: false,
  };
}

export function rowsFor(state: State): Row[] {
  if (state.review) {
    return REVIEW_ROWS;
  }

  const question = state.questions[state.current];

  return buildRows(
    question,
    state.current === state.questions.length - 1,
    state.questions.length === 1,
  );
}

/** Leave the freeform editor without recording anything. */
export function closeFreeform(state: State): State {
  return { ...state, freeform: false };
}

/**
 * Record typed text as the current question's answer and move on. Empty text
 * is a change of mind rather than an answer, so it just closes the editor.
 */
export function submitFreeform(state: State, text: string): { state: State } | { done: Outcome } {
  const trimmed = text.trim();

  if (trimmed === "") {
    return { state: closeFreeform(state) };
  }

  const next = copy(state);
  next.freeform = false;
  next.custom.set(next.questions[next.current].id, trimmed);

  // A single-select question is answered by the text, so clear any option
  // selection: the freeform value replaces it rather than joining it.
  if (!next.questions[next.current].multiple) {
    next.selections.set(next.questions[next.current].id, new Set());
  }

  return advance(next);
}

// Whether a question has a recorded answer. The tab bar draws a filled box
// from this, which for a single-select question in a batch is the only
// feedback that the answer landed: those draw no checkbox in the options list.
export function isAnswered(state: State, question: Question): boolean {
  return (
    (state.selections.get(question.id)?.size ?? 0) > 0 ||
    state.custom.get(question.id) !== undefined
  );
}

// Moving on from a question: the next one, review when there are no more, or
// straight to completion when there is only one question. A single question
// shows no review screen, and freeform is the one path that reaches here with
// questions.length === 1, so the check belongs here rather than at the caller.
function advance(state: State): { state: State } | { done: Outcome } {
  if (state.questions.length === 1) {
    return { done: { kind: "completed", answers: answersFrom(state, 1) } };
  }

  if (state.current === state.questions.length - 1) {
    return { state: { ...state, review: true, focus: 0 } };
  }

  return { state: { ...state, current: state.current + 1, focus: 0 } };
}

// Structural copy. The Map and Set values are rebuilt rather than shared so a
// returned state never aliases the one handed in, which is what lets tests
// assert on intermediate states.
function copy(state: State): State {
  return {
    ...state,
    selections: new Map([...state.selections].map(([k, v]) => [k, new Set(v)])),
    custom: new Map(state.custom),
  };
}

function answersFrom(state: State, upto: number): Answer[] {
  const answers: Answer[] = [];

  for (let i = 0; i < upto; i++) {
    const question = state.questions[i];
    const custom = state.custom.get(question.id);
    const values = [...(state.selections.get(question.id) ?? [])];

    if (custom !== undefined) {
      values.push(custom);
    }

    if (values.length > 0) {
      answers.push({ id: question.id, values, wasCustom: custom !== undefined });
    }
  }

  return answers;
}

function toggle(state: State, value: string): State {
  const next = copy(state);
  const question = next.questions[next.current];
  const set = next.selections.get(question.id) ?? new Set<string>();

  if (set.has(value)) {
    set.delete(value);
  } else {
    set.add(value);
  }

  next.selections.set(question.id, set);

  return next;
}

export function handleKey(
  state: State,
  key: Keypress,
): { state: State } | { done: Outcome } {
  const rows = rowsFor(state);

  // While the editor is open it owns every key: choices.ts routes input to it
  // and calls closeFreeform or submitFreeform, so nothing below should run.
  if (state.freeform) {
    return { state };
  }

  if (key.name === "escape") {
    return { done: { kind: "cancelled" } };
  }

  if (key.name === "left") {
    if (state.review) {
      return { state: { ...state, review: false, focus: 0 } };
    }

    return { state: { ...state, current: Math.max(0, state.current - 1), focus: 0 } };
  }

  if (key.name === "right") {
    // Review is reached through Next, not by arrowing off the end.
    if (state.review || state.current === state.questions.length - 1) {
      return { state };
    }

    return { state: { ...state, current: state.current + 1, focus: 0 } };
  }

  if (key.name === "up") {
    return { state: { ...state, focus: Math.max(0, state.focus - 1) } };
  }

  if (key.name === "down") {
    return { state: { ...state, focus: Math.min(rows.length - 1, state.focus + 1) } };
  }

  if (key.name === "digit") {
    const target = rows.findIndex(
      (row) => "number" in row && row.number === key.digit,
    );

    return target === -1
      ? { state }
      : activate({ ...state, focus: target }, rows[target]);
  }

  const row = rows[state.focus];

  if (key.name === "space") {
    const question = state.questions[state.current];

    return row.kind === "option" && question.multiple
      ? { state: toggle(state, row.option.value) }
      : { state };
  }

  if (key.name === "enter") {
    return activate(state, row);
  }

  return { state };
}

function activate(state: State, row: Row): { state: State } | { done: Outcome } {
  const question = state.questions[state.current];

  if (row.kind === "chat") {
    return {
      done: {
        kind: "chat",
        answers: answersFrom(state, state.current),
        questionId: question.id,
      },
    };
  }

  if (row.kind === "option") {
    if (question.multiple) {
      return { state: toggle(state, row.option.value) };
    }

    const next = copy(state);
    next.selections.set(question.id, new Set([row.option.value]));

    // Choosing is the whole interaction for a single-select question, so it
    // moves on by itself: the next question, review after the last one, or
    // straight to completion when it is the only question. Next stays in the
    // list for skipping without answering.
    return advance(next);
  }

  if (row.kind === "other") {
    return { state: { ...state, freeform: true } };
  }

  if (row.kind === "next") {
    return advance(state);
  }

  if (row.kind === "submit" || row.kind === "submit-answers") {
    return { done: { kind: "completed", answers: answersFrom(state, state.questions.length) } };
  }

  if (row.kind === "cancel") {
    return { done: { kind: "cancelled" } };
  }

  return { state };
}
