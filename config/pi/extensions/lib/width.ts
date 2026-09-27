// Width helpers shared by the extensions in this directory. pi-tui exports
// visibleWidth, truncateToWidth, and wrapTextWithAnsi, but that package only
// resolves inside pi: bare `node --test` cannot find it, and importing it here
// would take the dependent test suites down with it. These are the small
// subset those renderers need, kept dependency-free on purpose.

// SGR sequences only. That is all the theme emits, and it is what makes
// visible width differ from string length.
const ANSI = /\x1b\[[0-9;]*m/g;

// The same pattern anchored, for walking a string one sequence at a time.
const ANSI_AT_START = /^\x1b\[[0-9;]*m/;

const RESET = "\x1b[0m";

export function stripAnsi(text: string): string {
  return text.replace(ANSI, "");
}

// Visible columns, not code units. Wide characters (CJK, most emoji) occupy
// two columns; combining marks occupy none. Everything else counts as one.
export function visibleWidth(text: string): number {
  let width = 0;

  for (const char of stripAnsi(text)) {
    const code = char.codePointAt(0) ?? 0;

    // Combining marks and zero-width joiners take no space.
    if ((code >= 0x0300 && code <= 0x036f) || code === 0x200d || code === 0xfe0f) {
      continue;
    }

    width += isWide(code) ? 2 : 1;
  }

  return width;
}

// The East Asian Wide and Fullwidth ranges that actually turn up in terminal
// output. Not exhaustive: the cost of missing one is a column of drift, not a
// crash.
function isWide(code: number): boolean {
  return (
    (code >= 0x1100 && code <= 0x115f) ||
    (code >= 0x2e80 && code <= 0xa4cf) ||
    (code >= 0xac00 && code <= 0xd7a3) ||
    (code >= 0xf900 && code <= 0xfaff) ||
    (code >= 0xfe30 && code <= 0xfe6f) ||
    (code >= 0xff00 && code <= 0xff60) ||
    (code >= 0xffe0 && code <= 0xffe6) ||
    (code >= 0x1f300 && code <= 0x1f64f) ||
    (code >= 0x1f900 && code <= 0x1f9ff)
  );
}

// Cut a string to fit a column budget, marking the cut with an ellipsis.
//
// Colored input is the normal case here, so this walks the string rather than
// slicing it: escape sequences are copied through without consuming columns,
// and a reset is appended when any were seen, so a truncated run of color
// cannot bleed into the rest of the line.
export function truncate(text: string, width: number): string {
  if (width <= 0) {
    return "";
  }

  if (visibleWidth(text) <= width) {
    return text;
  }

  // The ellipsis occupies the last column, so the text budget is one short.
  const budget = width - 1;
  let out = "";
  let used = 0;
  let colored = false;
  let i = 0;

  while (i < text.length) {
    const escape = ANSI_AT_START.exec(text.slice(i));

    if (escape) {
      out += escape[0];
      colored = true;
      i += escape[0].length;
      continue;
    }

    // Iterate by code point: astral characters are two code units wide.
    const char = String.fromCodePoint(text.codePointAt(i) as number);
    const charWidth = visibleWidth(char);

    if (used + charWidth > budget) {
      break;
    }

    out += char;
    used += charWidth;
    i += char.length;
  }

  // Pad when a wide character straddles the boundary, so the result is exactly
  // the requested width rather than one short.
  const pad = " ".repeat(Math.max(0, budget - used));

  return `${out}${pad}…${colored ? RESET : ""}`;
}

// Wrap on word boundaries, falling back to a hard break for any single word
// longer than the line. Input here is plain text: the renderer wraps before it
// colorizes, so no escape sequence is ever split across lines.
export function wrapText(text: string, width: number): string[] {
  if (width <= 0) {
    return [text];
  }

  const lines: string[] = [];
  let line = "";

  for (const word of text.split(/\s+/).filter((w) => w !== "")) {
    const candidate = line === "" ? word : `${line} ${word}`;

    if (visibleWidth(candidate) <= width) {
      line = candidate;
      continue;
    }

    if (line !== "") {
      lines.push(line);
      line = "";
    }

    // A word that cannot fit on a line of its own gets chopped.
    let rest = word;

    while (visibleWidth(rest) > width) {
      let cut = "";

      for (const char of rest) {
        if (visibleWidth(cut + char) > width) {
          break;
        }

        cut += char;
      }

      lines.push(cut);
      rest = rest.slice(cut.length);
    }

    line = rest;
  }

  if (line !== "") {
    lines.push(line);
  }

  return lines.length > 0 ? lines : [""];
}
