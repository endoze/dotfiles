import { test } from "node:test";
import assert from "node:assert/strict";
import { render } from "./render.ts";
import { createState, handleKey } from "./state.ts";
import type { Question } from "./rows.ts";

const plain = {
  fg: (_c: string, t: string) => t,
  bg: (_c: string, t: string) => t,
  bold: (t: string) => t,
};

const draw = (state: Parameters<typeof render>[0]) => render(state, 60, plain).join("\n");

const policy: Question = {
  id: "policy",
  prompt: "What should the cache eviction policy be?",
  label: "Policy",
  options: [
    { value: "lru", label: "LRU", description: "Evict least recently used" },
    { value: "lfu", label: "LFU", description: "Evict least frequently used" },
  ],
  multiple: false,
  allowOther: true,
};

const caches: Question = {
  ...policy,
  id: "caches",
  prompt: "Which caches?",
  label: "Caches",
  allowOther: false,
};

test("single question: numbered options, Type something, bar, chat", () => {
  const out = draw(createState([policy]));
  assert.match(out, /1\. LRU/);
  assert.match(out, /Evict least recently used/);
  assert.match(out, /3\. Type something\./);
  assert.match(out, /4\. Chat about this/);
  assert.doesNotMatch(out, /Next/);
  // No tab bar and no counter for a single question.
  assert.doesNotMatch(out, /\[Q\d/);
  assert.doesNotMatch(out, /□|■/);
});

test("focused row is marked and unfocused rows are not", () => {
  const out = draw(createState([policy]));
  assert.match(out, /> 1\. LRU/);
  assert.doesNotMatch(out, /> 2\. LFU/);
});

test("multi-select shows checkboxes reflecting selection", () => {
  const state = createState([{ ...policy, multiple: true, allowOther: false }]);
  const after = handleKey(state, { name: "space" });
  assert.ok("state" in after);
  const out = draw(after.state);
  assert.match(out, /1\. \[x\] LRU/);
  assert.match(out, /2\. \[ \] LFU/);
  assert.match(out, /Select all that apply\./);
  assert.match(out, /Submit/);
});

test("Next keeps its indent, so it lines up under the option labels", () => {
  const out = draw(createState([policy, caches]));
  assert.match(out, /^ {5}Next$/m);
});

test("the help line wraps rather than being cut", () => {
  const lines = render(createState([policy, caches]), 44, plain);
  const joined = lines.join("\n");

  // The last word survives, so nothing was truncated away.
  assert.match(joined, /esc cancel/);

  for (const line of lines) {
    assert.ok(line.length <= 44, `line too wide: ${JSON.stringify(line)}`);
  }
});

test("multi-question shows the tab bar and Next, never a counter", () => {
  const out = draw(createState([policy, caches]));
  assert.match(out, /←/);
  assert.match(out, /□ Policy/);
  assert.match(out, /□ Caches/);
  assert.match(out, /→/);
  assert.match(out, /Next/);
  assert.doesNotMatch(out, /\[Q\d/);
});

test("answering a question fills its box in the tab bar", () => {
  const state = createState([policy, caches]);
  const answered = handleKey(state, { name: "enter" });
  assert.ok("state" in answered);
  const out = draw(answered.state);
  assert.match(out, /■ Policy/);
  assert.match(out, /□ Caches/);
});

// Both questions are single-select, so one Enter each answers and advances,
// landing on review.
const toReview = [{ name: "enter" as const }, { name: "enter" as const }];

const drive = (keys: { name: "enter" | "down" }[]) => {
  let state = createState([policy, caches]);

  for (const k of keys) {
    const r = handleKey(state, k);
    assert.ok("state" in r);
    state = r.state;
  }

  return state;
};

test("the tab bar is present on the review screen too", () => {
  const out = draw(drive(toReview));
  assert.match(out, /Review your answers/);
  assert.match(out, /■ Policy/);
  assert.match(out, /■ Caches/);
});

test("freeform mode shows the label, the editor's lines, and its own help", () => {
  const state = createState([policy]);
  const opened = handleKey(state, { name: "digit", digit: 3 });
  assert.ok("state" in opened);

  // choices.ts renders the Editor and hands its lines in.
  const out = render(opened.state, 60, plain, ["  > typed text"]).join("\n");

  assert.match(out, /Your answer:/);
  assert.match(out, /typed text/);
  assert.match(out, /Esc to go back/);
});

test("editor lines appear only while freeform is open", () => {
  const out = render(createState([policy]), 60, plain, ["  > leaked"]).join("\n");
  assert.doesNotMatch(out, /leaked/);
});

test("review lists answers then the two numbered rows", () => {
  const out = draw(drive(toReview));
  assert.match(out, /Review your answers/);
  assert.match(out, /1\. Submit answers/);
  assert.match(out, /2\. Cancel/);
});

test("every line fits the requested width", () => {
  for (const width of [60, 40, 24]) {
    for (const line of render(createState([policy]), width, plain)) {
      assert.ok(line.length <= width, `line too wide at ${width}: ${JSON.stringify(line)}`);
    }
  }
});

const varied: Question = {
  id: "varied",
  prompt: "Pick one",
  label: "Varied",
  options: [
    { value: "a", label: "A", description: "short label" },
    { value: "b", label: "Much longer label", description: "long label" },
    { value: "c", label: "Mid", description: "middling" },
  ],
  multiple: false,
  allowOther: false,
};

test("every description starts on its own line at the label column", () => {
  const lines = render(createState([varied]), 60, plain);

  // Never beside the label, however short the label is.
  for (const line of lines) {
    assert.doesNotMatch(
      line,
      /\d\. \S.*(short label|long label|middling)/,
      `description sits beside its label: ${JSON.stringify(line)}`,
    );
  }

  // Each one on its own line, at column 5 ("  " plus "N. ").
  for (const text of ["short label", "long label", "middling"]) {
    assert.ok(
      lines.some((line) => line === `     ${text}`),
      `${text} not on its own line at column 5: ${JSON.stringify(lines)}`,
    );
  }
});

test("a long prompt wraps instead of being cut", () => {
  const long = {
    ...policy,
    prompt:
      "Given the current cache sizing and the traffic pattern we saw last quarter, what should the eviction policy be?",
  };
  const out = draw(createState([long]));

  // Every word survives somewhere in the output.
  for (const word of ["sizing", "traffic", "quarter", "eviction"]) {
    assert.match(out, new RegExp(word));
  }
});

test("a wrapped label continues at the label column, not a deeper indent", () => {
  const long: Question = {
    ...policy,
    allowOther: false,
    options: [
      {
        value: "lru",
        label: "Least recently used with a second chance queue and a tunable window",
        description: "Evicts the coldest entry once the window closes",
      },
    ],
  };
  const lines = render(createState([long]), 40, plain);

  // "  " indent plus "1. " is 5 columns, so every continuation starts there.
  const body = lines.filter((line) => /\S/.test(line) && !/^[─]/.test(line));
  const wrapped = body.filter((line) => /^ {5}\S/.test(line));

  assert.ok(wrapped.length >= 2, `expected continuation lines: ${JSON.stringify(body)}`);

  for (const line of wrapped) {
    assert.doesNotMatch(line, /^ {6,}/, `over-indented: ${JSON.stringify(line)}`);
  }

  // The description dropped to its own line, also at column 5.
  assert.ok(
    lines.some((line) => /^ {5}Evicts/.test(line)),
    `description not at label column: ${JSON.stringify(lines)}`,
  );
});

test("multi-select continuation clears the checkbox too", () => {
  const long: Question = {
    ...policy,
    multiple: true,
    allowOther: false,
    options: [
      {
        value: "frag",
        label: "Rendered fragments and partial template output",
        description: "Cached HTML for hot pages",
      },
    ],
  };
  const lines = render(createState([long]), 40, plain);

  // "  " plus "1. " plus "[ ] " is 9 columns.
  assert.ok(
    lines.some((line) => /^ {9}\S/.test(line)),
    `no continuation at the checkbox column: ${JSON.stringify(lines)}`,
  );
  assert.ok(
    lines.some((line) => /^ {9}Cached HTML/.test(line)),
    `description not at label column: ${JSON.stringify(lines)}`,
  );
});

test("a long option label wraps and its continuation is indented", () => {
  const long: Question = {
    ...policy,
    allowOther: false,
    options: [
      {
        value: "lru",
        label: "Least recently used with a second chance queue and a tunable window",
        description: "Evicts the coldest entry once the window closes",
      },
    ],
  };
  const lines = render(createState([long]), 40, plain);

  for (const line of lines) {
    assert.ok(line.length <= 40, `line too wide: ${JSON.stringify(line)}`);
  }

  const joined = lines.join("\n");
  assert.match(joined, /tunable window/);
  assert.match(joined, /coldest/);
  assert.match(joined, /closes/);

  // A cramped description drops to its own line rather than wrapping into a
  // one-character column, which used to emit a run of blank padding lines.
  assert.ok(
    lines.filter((line) => line.trim() === "").length <= 3,
    `too many blank lines: ${JSON.stringify(lines)}`,
  );
});

test("width is measured in visible columns, not ANSI bytes", () => {
  // A theme that emits real escape codes. Lines must still fit the width:
  // measuring line.length would count the escapes and cut visible text.
  const ansi = {
    fg: (_c: string, t: string) => `\x1b[31m${t}\x1b[0m`,
    bg: (_c: string, t: string) => `\x1b[41m${t}\x1b[0m`,
    bold: (t: string) => `\x1b[1m${t}\x1b[0m`,
  };

  const strip = (s: string) => s.replace(/\x1b\[[0-9;]*m/g, "");

  for (const line of render(createState([policy]), 40, ansi)) {
    assert.ok(
      strip(line).length <= 40,
      `visible width exceeds 40: ${JSON.stringify(strip(line))}`,
    );
  }
});
