// Every visual surface the todo list has: the transcript block, the widget
// above the editor, and the /todos overlay. Pure (state and a theme callback
// in, lines out) so each screen is assertable as plain text.

import { counts, type Todo } from "./state.ts";
import { truncate, visibleWidth } from "../lib/width.ts";

/**
 * The subset of pi's Theme this module uses, declared structurally so the
 * module stays free of pi imports and therefore testable outside pi. The color
 * names are spelled out rather than widened to `string` so that a real Theme
 * remains assignable to this and typos in color names are caught.
 */
export type ThemeColorName =
  | "accent"
  | "borderMuted"
  | "dim"
  | "muted"
  | "success"
  | "text";

export interface RenderTheme {
  fg: (color: ThemeColorName, text: string) => string;
  bold: (text: string) => string;
}

/**
 * Glyphs mirror the three statuses. Filled for done, half for in progress,
 * hollow for untouched, so the list's shape reads at a glance without color.
 */
const MARKS: Record<Todo["status"], string> = {
  completed: "✓",
  in_progress: "◐",
  pending: "○",
};

const COLORS: Record<Todo["status"], ThemeColorName> = {
  completed: "dim",
  in_progress: "accent",
  pending: "muted",
};

/** Transcript lines shown when a tool result is collapsed. */
const COLLAPSED_LIMIT = 4;

/** Items shown before and after the current one in the widget. */
const WINDOW_BACK = 1;
const WINDOW_AHEAD = 2;

export interface WidgetWindow {
  /** Index of the current item. */
  current: number;
  /** First index shown, inclusive. */
  start: number;
  /** Last index shown, exclusive. */
  end: number;
}

/**
 * The slice of the list the widget shows, centered on the current item: the
 * one in progress, or the first pending one when the list is stalled.
 *
 * The window shrinks at the ends rather than borrowing from the other side.
 * Constant height would mean padding a two-item list with completed work,
 * which is the one thing the widget has no reason to show.
 *
 * Absence doubles as the widget's emptiness test. A list with nothing in
 * progress and nothing pending is either empty or finished, and neither is
 * worth a permanent row above the editor.
 */
export function widgetWindow(todos: readonly Todo[]): WidgetWindow | undefined {
  const active = todos.findIndex((todo) => todo.status === "in_progress");
  const current = active === -1 ? todos.findIndex((todo) => todo.status === "pending") : active;

  if (current === -1) {
    return undefined;
  }

  return {
    current,
    start: Math.max(0, current - WINDOW_BACK),
    end: Math.min(todos.length, current + WINDOW_AHEAD + 1),
  };
}

function line(todo: Todo, width: number, theme: RenderTheme, active = false): string {
  const mark = theme.fg(COLORS[todo.status], MARKS[todo.status]);
  const text = theme.fg(COLORS[todo.status], active ? todo.activeForm : todo.content);
  // Strikethrough is deliberately not used: it renders inconsistently across
  // terminals, and the dim color plus the check already carry "done".
  const prefix = "  ";

  return `${prefix}${mark} ${truncate(text, Math.max(1, width - visibleWidth(prefix) - 2))}`;
}

/**
 * The full list, one item per line.
 *
 * Collapsed results show the head of the list rather than a window around the
 * active item: the plan reads top-to-bottom, and a window that scrolls as work
 * progresses makes the transcript hard to scan after the fact.
 */
export function renderList(
  todos: readonly Todo[],
  width: number,
  theme: RenderTheme,
  options: { expanded?: boolean } = {},
): string[] {
  if (todos.length === 0) {
    return [theme.fg("dim", "  No todos")];
  }

  const { total, completed } = counts(todos);
  const header = theme.fg("muted", `  ${completed}/${total} completed`);
  const shown = options.expanded ? todos : todos.slice(0, COLLAPSED_LIMIT);
  const lines = shown.map((todo) => line(todo, width, theme));
  const hidden = todos.length - shown.length;

  if (hidden > 0) {
    lines.push(theme.fg("dim", `  … ${hidden} more`));
  }

  return [header, ...lines];
}

/**
 * The rows above the editor.
 *
 * A header carrying position and what is hidden above, the window of items,
 * then what is hidden below. Position is 1-based and counts the current item
 * rather than finished ones: it answers "where am I", not "how far along am
 * I", and a list nobody has finished still starts at one.
 *
 * Returns undefined when there is nothing worth a permanent row: no list, or a
 * finished one. The caller clears the widget on undefined, so the rows cost
 * nothing when idle.
 */
export function renderWidget(
  todos: readonly Todo[],
  width: number,
  theme: RenderTheme,
): string[] | undefined {
  const window = widgetWindow(todos);

  if (window === undefined) {
    return undefined;
  }

  const { current, start, end } = window;
  const below = todos.length - end;
  const position = `${current + 1}/${todos.length}`;
  const header = start > 0 ? `${position} · ${start} above` : position;
  const lines = [theme.fg("dim", truncate(`  ${header}`, width))];

  for (const todo of todos.slice(start, end)) {
    lines.push(line(todo, width, theme, todo.status === "in_progress"));
  }

  if (below > 0) {
    lines.push(theme.fg("dim", truncate(`  … ${below} below`, width)));
  }

  return lines;
}

/** The /todos overlay: framed, always expanded, with a dismissal hint. */
export function renderOverlay(
  todos: readonly Todo[],
  width: number,
  theme: RenderTheme,
): string[] {
  const title = theme.fg("accent", " Todos ");
  const rule = theme.fg("borderMuted", "─".repeat(3));
  const tail = theme.fg("borderMuted", "─".repeat(Math.max(0, width - visibleWidth(title) - 3)));

  return [
    "",
    truncate(`${rule}${title}${tail}`, width),
    "",
    ...renderList(todos, width, theme, { expanded: true }),
    "",
    theme.fg("dim", "  Press Escape to close"),
    "",
  ];
}
