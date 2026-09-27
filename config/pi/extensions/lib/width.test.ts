import { test } from "node:test";
import assert from "node:assert/strict";
import { stripAnsi, truncate, visibleWidth, wrapText } from "./width.ts";

test("visibleWidth ignores SGR escapes", () => {
  assert.equal(visibleWidth("abc"), 3);
  assert.equal(visibleWidth("\x1b[31mabc\x1b[0m"), 3);
  assert.equal(stripAnsi("\x1b[31mabc\x1b[0m"), "abc");
});

test("visibleWidth counts wide characters as two columns", () => {
  assert.equal(visibleWidth("日本"), 4);
  assert.equal(visibleWidth("a日"), 3);
});

test("wrapText breaks on word boundaries", () => {
  assert.deepEqual(wrapText("one two three", 7), ["one two", "three"]);
});

test("wrapText hard-breaks a word longer than the width", () => {
  assert.deepEqual(wrapText("abcdefghij", 4), ["abcd", "efgh", "ij"]);
});

test("wrapText returns a single empty line for empty input", () => {
  assert.deepEqual(wrapText("", 10), [""]);
});

test("no wrapped line exceeds the width", () => {
  const text = "the quick brown fox jumps over the lazy dog near a riverbank";

  for (const width of [10, 20, 33]) {
    for (const line of wrapText(text, width)) {
      assert.ok(visibleWidth(line) <= width, `too wide at ${width}: ${line}`);
    }
  }
});

test("truncate leaves text that already fits", () => {
  assert.equal(truncate("abc", 5), "abc");
  assert.equal(truncate("abc", 3), "abc");
});

test("truncate appends an ellipsis within the budget", () => {
  assert.equal(truncate("abcdef", 4), "abc…");
  assert.equal(visibleWidth(truncate("abcdef", 4)), 4);
});

test("truncate preserves color and closes the sequence", () => {
  const colored = "\x1b[31mabcdef\x1b[0m";
  const result = truncate(colored, 4);

  assert.equal(visibleWidth(result), 4);
  assert.equal(stripAnsi(result), "abc…");
  assert.ok(result.includes("\x1b[31m"));
  assert.ok(result.endsWith("\x1b[0m"));
});

test("truncate accounts for wide characters", () => {
  assert.equal(visibleWidth(truncate("日本語テキスト", 5)), 5);
});

test("truncate handles degenerate widths", () => {
  assert.equal(truncate("abc", 0), "");
  assert.equal(truncate("abc", -1), "");
  assert.equal(truncate("", 5), "");
});
