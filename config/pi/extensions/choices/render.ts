// The entire visual spec. Pure: state in, lines out, so every screen is
// assertable as text. Colors arrive as a theme callback rather than being
// baked in, which is also what lets tests pass an identity theme.

import type { Row } from "./rows.ts";
import { isAnswered, rowsFor, type State } from "./state.ts";
import { visibleWidth, wrapText } from "../lib/width.ts";

/**
 * The subset of pi's Theme this module uses. Color names are spelled out
 * rather than widened to `string` so a real Theme stays assignable here and
 * typos in color names are caught.
 */
export type ThemeColorName = "accent" | "dim" | "muted" | "success" | "text" | "warning";

export interface RenderTheme {
  fg: (color: ThemeColorName, text: string) => string;
  bg: (color: "selectedBg", text: string) => string;
  bold: (text: string) => string;
}

const HELP_LIST_SINGLE = "↑↓ navigate • enter select • esc cancel";
const HELP_LIST_MULTI = "↑↓ navigate • ←→ questions • enter select • esc cancel";
const HELP_REVIEW = "← back • enter select • esc cancel";
const HELP_FREEFORM = "Enter to submit • Esc to go back";

// Two leading spaces before every row, plus the "> " focus marker.
const INDENT = 2;

// A description always starts on its own line, at the same column its label
// starts in. No shared column, no side-by-side, no gap to compute: one rule
// that holds at every width and for every mix of label lengths.

// Wrap plain text, then colorize each line. Doing it the other way round would
// let a wrap land inside an escape sequence and split it across lines.
function wrapColored(
  text: string,
  width: number,
  color: (s: string) => string,
  prefix: string,
  continuation: string,
): string[] {
  const available = Math.max(1, width - visibleWidth(prefix));

  return wrapText(text, available).map(
    (line, i) => `${i === 0 ? prefix : continuation}${color(line)}`,
  );
}

// The tab bar: one box per question, filled when answered, active tab
// highlighted with a background rather than a marker so position reads at a
// glance. Status display only, never an input target: digits address the
// numbered rows in the body, so a tab never carries a number.
function renderTabs(state: State, theme: RenderTheme): string {
  const tabs = state.questions.map((question, i) => {
    const answered = isAnswered(state, question);
    const text = ` ${answered ? "■" : "□"} ${question.label} `;

    // Review is past the last question, so no tab is active there.
    return !state.review && i === state.current
      ? theme.bg("selectedBg", theme.fg("text", text))
      : theme.fg(answered ? "success" : "muted", text);
  });

  return `  ${theme.fg("dim", "←")} ${tabs.join(" ")} ${theme.fg("dim", "→")}`;
}

export function render(
  state: State,
  width: number,
  theme: RenderTheme,
  /**
   * Lines from pi's Editor, already rendered by choices.ts. Passed in rather
   * than produced here so this module stays pure and free of pi-tui, which is
   * what lets it be tested outside pi.
   */
  editorLines: string[] = [],
): string[] {
  const w = Math.max(1, width);
  const bar = theme.fg("accent", "─".repeat(w));
  const isMulti = state.questions.length > 1;
  // A backstop only: everything above wraps to width, so this should never
  // fire. It measures visible columns, since line.length counts escape bytes
  // and would cut real text with a live theme.
  const clamp = (lines: string[]) =>
    lines.map((line) => (visibleWidth(line) > w ? truncateVisible(line, w) : line));
  const lines: string[] = [bar];

  if (isMulti) {
    lines.push(renderTabs(state, theme));
  }

  lines.push("");

  if (state.review) {
    return clamp([
      ...lines,
      ...renderReview(state, theme, w),
      "",
      ...wrapColored(HELP_REVIEW, w, (s) => theme.fg("dim", s), "  ", "  "),
      bar,
    ]);
  }

  const question = state.questions[state.current];
  const rows = rowsFor(state);

  lines.push(
    ...wrapColored(question.prompt, w, (s) => theme.fg("text", s), "  ", "  "),
  );

  if (question.multiple) {
    lines.push(`  ${theme.fg("muted", "Select all that apply.")}`);
  }

  lines.push("");

  // Everything above the bar answers the question; everything below leaves it.
  // The split is what makes the unnumbered Next readable as "not a choice".
  const belowBar = rows.findIndex((row) => row.kind === "chat");

  for (let i = 0; i < rows.length; i++) {
    if (i === belowBar) {
      lines.push(bar);
    }

    lines.push(...renderRow(rows[i], i === state.focus, state, theme, w));
  }

  if (state.freeform) {
    lines.push("", `  ${theme.fg("muted", "Your answer:")}`, ...editorLines);
  }

  const help = state.freeform ? HELP_FREEFORM : isMulti ? HELP_LIST_MULTI : HELP_LIST_SINGLE;

  lines.push("", ...wrapColored(help, w, (s) => theme.fg("dim", s), "  ", "  "), bar);

  return clamp(lines);
}

// Where a row's text starts, past the indent, the number, and any checkbox.
// Wrapped lines and dropped descriptions both align here, so everything in a
// row lines up under its own first word rather than at some deeper column.
function labelColumn(row: Row, multiple: boolean): number {
  if (row.kind !== "option") {
    return INDENT;
  }

  return INDENT + visibleWidth(`${row.number}. ${multiple ? "[ ] " : ""}`);
}

function renderRow(
  row: Row,
  focused: boolean,
  state: State,
  theme: RenderTheme,
  width: number,
): string[] {
  const prefix = focused ? theme.fg("accent", "> ") : "  ";
  const color = (s: string) => theme.fg(focused ? "accent" : "text", s);
  const question = state.questions[state.current];
  const column = labelColumn(row, question.multiple);
  const continuation = " ".repeat(column);
  const label = (text: string) => wrapColored(text, width, color, prefix, continuation);

  if (row.kind === "option") {
    const box = question.multiple
      ? `${state.selections.get(question.id)?.has(row.option.value) ? "[x]" : "[ ]"} `
      : "";
    const head = `${row.number}. ${box}${row.option.label}`;
    const lines = wrapColored(head, width, color, prefix, continuation);

    if (row.option.description === undefined) {
      return lines;
    }

    for (const line of wrapText(row.option.description, Math.max(1, width - column))) {
      lines.push(`${continuation}${theme.fg("muted", line)}`);
    }

    return lines;
  }

  if (row.kind === "other") {
    return label(`${row.number}. Type something.`);
  }

  if (row.kind === "chat") {
    return label(`${row.number}. Chat about this`);
  }

  if (row.kind === "submit-answers") {
    return label(`${row.number}. Submit answers`);
  }

  if (row.kind === "cancel") {
    return label(`${row.number}. Cancel`);
  }

  // Next and Submit carry no number: a digit would imply a 1-9 hotkey, and
  // these are not choices. The indent is applied to the prefix rather than the
  // text, since wrapping splits on whitespace and would eat leading spaces.
  return [`${prefix}   ${color(row.kind === "next" ? "Next" : "Submit")}`];
}

// Cut to a visible column count without splitting an escape sequence: the
// codes are copied through and only printable characters count toward width.
function truncateVisible(line: string, width: number): string {
  let out = "";
  let used = 0;
  let i = 0;

  while (i < line.length) {
    const escape = /^\x1b\[[0-9;]*m/.exec(line.slice(i));

    if (escape) {
      out += escape[0];
      i += escape[0].length;
      continue;
    }

    const char = line[i];
    const next = used + visibleWidth(char);

    if (next > width) {
      break;
    }

    out += char;
    used = next;
    i += 1;
  }

  return out;
}

function renderReview(state: State, theme: RenderTheme, width: number): string[] {
  const lines = [`  ${theme.fg("accent", theme.bold("Review your answers"))}`, ""];

  for (const question of state.questions) {
    const custom = state.custom.get(question.id);
    const picked = [...(state.selections.get(question.id) ?? [])].map(
      (value) => question.options.find((o) => o.value === value)?.label ?? value,
    );

    if (custom !== undefined) {
      picked.push(custom);
    }

    lines.push(...wrapColored(question.prompt, width, (s) => theme.fg("text", s), "  ", "  "));
    lines.push(
      ...wrapColored(
        picked.join(", ") || "(no answer)",
        width,
        (s) => theme.fg("muted", s),
        "    ",
        "    ",
      ),
    );
  }

  lines.push("");

  const rows = rowsFor(state);

  for (let i = 0; i < rows.length; i++) {
    lines.push(...renderRow(rows[i], i === state.focus, state, theme, width));
  }

  return lines;
}
