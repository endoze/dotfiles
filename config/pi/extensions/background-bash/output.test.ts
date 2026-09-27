import assert from "node:assert/strict";
import { test } from "node:test";
import {
  MAX_OUTPUT_BYTES,
  MAX_OUTPUT_LINES,
  OutputTail,
  type TailTruncator,
} from "./output.ts";

const bytes = (text: string): Uint8Array => Buffer.from(text, "utf8");

test("keeps ordinary output unchanged", () => {
  const output = new OutputTail();
  output.append(bytes("one\n"));
  output.append(bytes("two\n"));
  output.finish();

  assert.deepEqual(output.snapshot(), {
    text: "one\ntwo\n",
    truncated: false,
  });
  assert.equal(output.format(), "one\ntwo");
});

test("decodes a UTF-8 code point split across chunks", () => {
  const output = new OutputTail();
  const encoded = Buffer.from("A€B", "utf8");
  output.append(encoded.subarray(0, 2));
  output.append(encoded.subarray(2, 3));
  output.append(encoded.subarray(3));
  output.finish();

  assert.equal(output.snapshot().text, "A€B");
  assert.equal(output.snapshot().text.includes("\uFFFD"), false);
});

test("keeps the newest bytes without cutting a UTF-8 continuation", () => {
  const output = new OutputTail();
  output.append(bytes(`${"x".repeat(MAX_OUTPUT_BYTES)}€tail`));
  output.finish();

  const snapshot = output.snapshot();
  assert.equal(snapshot.truncated, true);
  assert.ok(Buffer.byteLength(snapshot.text, "utf8") <= MAX_OUTPUT_BYTES);
  assert.ok(snapshot.text.endsWith("€tail"));
  assert.equal(snapshot.text.includes("\uFFFD"), false);
});

test("keeps at most the newest 2000 lines", () => {
  const output = new OutputTail();
  const lines = Array.from(
    { length: MAX_OUTPUT_LINES + 3 },
    (_, index) => `line-${index + 1}`,
  );
  output.append(bytes(lines.join("\n")));
  output.finish();

  const snapshot = output.snapshot();
  assert.equal(snapshot.truncated, true);
  assert.equal(snapshot.text.split("\n").length, MAX_OUTPUT_LINES);
  assert.equal(snapshot.text.startsWith("line-4\n"), true);
  assert.equal(snapshot.text.endsWith(`line-${MAX_OUTPUT_LINES + 3}`), true);
});

test("does not truncate exactly 2000 newline-terminated lines", () => {
  const output = new OutputTail();
  const text = `${Array.from(
    { length: MAX_OUTPUT_LINES },
    (_, index) => `line-${index + 1}`,
  ).join("\n")}\n`;
  output.append(bytes(text));
  output.finish();

  assert.deepEqual(output.snapshot(), { text, truncated: false });
});

test("truncates 2001 newline-terminated lines from the head", () => {
  const output = new OutputTail();
  output.append(
    bytes(
      `${Array.from(
        { length: MAX_OUTPUT_LINES + 1 },
        (_, index) => `line-${index + 1}`,
      ).join("\n")}\n`,
    ),
  );
  output.finish();

  const snapshot = output.snapshot();
  assert.equal(snapshot.truncated, true);
  assert.equal(snapshot.text.split("\n").length, MAX_OUTPUT_LINES);
  assert.equal(snapshot.text.startsWith("line-2\n"), true);
  assert.equal(snapshot.text.endsWith(`line-${MAX_OUTPUT_LINES + 1}`), true);
});

test("format marks truncation and handles empty output", () => {
  const truncated = new OutputTail();
  truncated.append(bytes("x".repeat(MAX_OUTPUT_BYTES + 1)));
  truncated.finish();
  assert.match(
    truncated.format(),
    /^\[Earlier output truncated to the last 50 KiB or 2,000 lines\]\n/,
  );

  const empty = new OutputTail();
  empty.finish();
  assert.equal(empty.format(), "(no output)");
});

test("preserves a streamed line boundary after Pi-style tail truncation", () => {
  const piStyleTruncate: TailTruncator = (content, options) => {
    const lines = content.endsWith("\n")
      ? content.slice(0, -1).split("\n")
      : content.split("\n");
    return lines.length > options.maxLines
      ? {
          content: lines.slice(-options.maxLines).join("\n"),
          truncated: true,
        }
      : { content, truncated: false };
  };
  const output = new OutputTail(piStyleTruncate);
  output.append(
    bytes(
      `${Array.from(
        { length: MAX_OUTPUT_LINES + 1 },
        (_, index) => `line-${index + 1}`,
      ).join("\n")}\n`,
    ),
  );
  output.append(bytes("next-line\n"));
  output.finish();

  assert.match(output.snapshot().text, /line-2001\nnext-line$/);
  assert.equal(output.snapshot().text.includes("line-2001next-line"), false);
});

test("accepts a Pi truncateTail-compatible policy", () => {
  const calls: Array<{ maxBytes: number; maxLines: number }> = [];
  const truncate: TailTruncator = (_content, options) => {
    calls.push(options);
    return { content: "kept", truncated: true };
  };
  const output = new OutputTail(truncate);
  output.append(bytes("original"));

  assert.deepEqual(calls.at(-1), {
    maxBytes: MAX_OUTPUT_BYTES,
    maxLines: MAX_OUTPUT_LINES,
  });
  assert.deepEqual(output.snapshot(), { text: "kept", truncated: true });
});
