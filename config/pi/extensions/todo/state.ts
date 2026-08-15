// The todo list itself: validation and reconstruction. Pure on purpose (no
// terminal, no theme, no pi imports) so the rules that matter, meaning what
// counts as a valid list and what the list is at a given point in history, are
// testable with bare `node --test`.

export type Status = "pending" | "in_progress" | "completed";

export interface Todo {
  /** Imperative form, shown in the list: "Add the widget". */
  content: string;
  status: Status;
  /** Present continuous, shown while active: "Adding the widget". */
  activeForm: string;
}

/** Stored on every tool result. The list here IS the state at that entry. */
export interface TodoDetails {
  todos: Todo[];
}

/**
 * Guardrail against a runaway model turning the list into a novel. Chosen well
 * above any plausible real plan: hitting this means something has gone wrong,
 * not that the user has an ambitious afternoon.
 */
export const MAX_TODOS = 50;

export type Validation =
  | { ok: true; todos: Todo[] }
  | { ok: false; error: string };

const STATUSES: Status[] = ["pending", "in_progress", "completed"];

function isStatus(value: unknown): value is Status {
  return typeof value === "string" && (STATUSES as string[]).includes(value);
}

/**
 * Validate a whole proposed list.
 *
 * The contract is whole-list replacement, so this runs on every call and the
 * previous list is never consulted: a call either describes a legal list or is
 * rejected outright. Errors are returned rather than thrown because they are
 * handed back to the model as tool output for it to correct.
 */
export function validate(input: unknown): Validation {
  if (!Array.isArray(input)) {
    return { ok: false, error: "todos must be an array" };
  }

  if (input.length > MAX_TODOS) {
    return { ok: false, error: `too many todos (${input.length}); the maximum is ${MAX_TODOS}` };
  }

  const todos: Todo[] = [];

  for (const [i, raw] of input.entries()) {
    if (typeof raw !== "object" || raw === null) {
      return { ok: false, error: `todo ${i + 1} is not an object` };
    }

    const { content, status, activeForm } = raw as Record<string, unknown>;

    if (typeof content !== "string" || content.trim() === "") {
      return { ok: false, error: `todo ${i + 1} needs a non-empty content` };
    }

    if (typeof activeForm !== "string" || activeForm.trim() === "") {
      return { ok: false, error: `todo ${i + 1} needs a non-empty activeForm` };
    }

    if (!isStatus(status)) {
      return {
        ok: false,
        error: `todo ${i + 1} has an invalid status; expected ${STATUSES.join(", ")}`,
      };
    }

    todos.push({ content: content.trim(), status, activeForm: activeForm.trim() });
  }

  // One active item at a time. This is the rule that keeps the widget
  // unambiguous (it shows a single activeForm) and keeps the model honest
  // about doing one thing at a time rather than marking everything started.
  const active = todos.filter((todo) => todo.status === "in_progress");

  if (active.length > 1) {
    return {
      ok: false,
      error: `only one todo may be in_progress at a time (found ${active.length})`,
    };
  }

  return { ok: true, todos };
}

/**
 * A session entry, narrowed to just the shape this module reads. Declared
 * structurally rather than imported from pi so the module stays loadable, and
 * therefore testable, outside pi.
 */
export interface BranchEntry {
  type: string;
  message?: {
    role: string;
    toolName?: string;
    details?: unknown;
  };
}

/**
 * The list stored on a tool result, or undefined if that result carries none.
 *
 * A rejected call still gets a details object, just an empty one: pi records a
 * thrown tool with `details: {}` rather than omitting the field. Truthiness
 * therefore cannot tell a stored list from a rejection, and every reader has to
 * look for the array itself. Sharing that check is what keeps two readers from
 * disagreeing about it, which is a crash for whichever one guesses wrong.
 *
 * An empty array is a list, not an absence: it is how a clear is recorded.
 */
export function todosFrom(details: unknown): Todo[] | undefined {
  const todos = (details as TodoDetails | undefined | null)?.todos;

  return Array.isArray(todos) ? todos : undefined;
}

/**
 * Rebuild the current list by replaying the branch.
 *
 * State lives in tool results rather than a file or a module-level variable so
 * that history navigation is correct for free: `/tree`, `/fork`, and branch
 * switching all change which entries are on the branch, and the list follows.
 * A file on disk would keep the newest list regardless of where you navigated.
 *
 * Every call replaces the whole list, so the last result on the branch wins and
 * earlier ones need no merging.
 */
export function reconstruct(entries: readonly BranchEntry[], toolName: string): Todo[] {
  let todos: Todo[] = [];

  for (const entry of entries) {
    if (entry.type !== "message") continue;

    const message = entry.message;

    if (!message || message.role !== "toolResult" || message.toolName !== toolName) {
      continue;
    }

    // A rejected call carries no list; skipping leaves the prior one intact,
    // which matches what the model was told happened.
    const stored = todosFrom(message.details);

    if (stored) {
      todos = stored;
    }
  }

  return todos;
}

export interface Counts {
  total: number;
  completed: number;
  pending: number;
  active: Todo | undefined;
}

export function counts(todos: readonly Todo[]): Counts {
  return {
    total: todos.length,
    completed: todos.filter((todo) => todo.status === "completed").length,
    pending: todos.filter((todo) => todo.status === "pending").length,
    active: todos.find((todo) => todo.status === "in_progress"),
  };
}

/**
 * The text handed back to the model. It restates the full list because the
 * model just sent one: echoing it back is the acknowledgement that the write
 * landed, and it re-anchors the plan in context on long turns.
 */
export function summarize(todos: readonly Todo[]): string {
  if (todos.length === 0) {
    return "Todo list cleared.";
  }

  const { total, completed } = counts(todos);
  const lines = todos.map((todo) => {
    const mark = todo.status === "completed" ? "x" : todo.status === "in_progress" ? "~" : " ";

    return `[${mark}] ${todo.content}`;
  });

  return [`Todos (${completed}/${total} completed):`, ...lines].join("\n");
}
