// Registers `todo_write`, a task list the model rewrites in whole on every
// call, plus the surfaces that show it: a transcript block, a persistent line
// above the editor, and a `/todos` overlay. pi auto-loads
// ~/.pi/agent/extensions/*.ts, which is a symlink to config/pi/extensions in
// this repo, so no settings.json entry is needed. The todo/ subdirectory is not
// auto-loaded: pi descends into a subdirectory only for index.ts, index.js, or
// a package.json declaring pi.extensions, and that directory has none.

import type {
  AgentToolResult,
  ExtensionAPI,
  ExtensionContext,
  Theme,
} from "@earendil-works/pi-coding-agent";
import { matchesKey, Key, Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import { renderList, renderOverlay, renderWidget } from "./todo/render.ts";
import {
  reconstruct,
  summarize,
  type Todo,
  type TodoDetails,
  todosFrom,
  validate,
} from "./todo/state.ts";

const TOOL_NAME = "todo_write";
const WIDGET_ID = "todo";

const TodoSchema = Type.Object({
  content: Type.String({
    description: "The task in imperative form, e.g. 'Add the widget'",
  }),
  status: Type.Union(
    [Type.Literal("pending"), Type.Literal("in_progress"), Type.Literal("completed")],
    { description: "Task state. At most one task may be in_progress at a time." },
  ),
  activeForm: Type.String({
    description: "Present continuous form shown while the task is active, e.g. 'Adding the widget'",
  }),
});

const TodoWriteParams = Type.Object({
  todos: Type.Array(TodoSchema, {
    description: "The complete task list. This replaces the previous list entirely.",
  }),
});

/**
 * The widget has no width of its own: pi renders it as a component, so the
 * width arrives at render time. Passing a callback rather than pre-rendered
 * lines keeps it correct across terminal resizes.
 */
function showWidget(ctx: ExtensionContext, todos: readonly Todo[]): void {
  if (!ctx.hasUI || ctx.mode !== "tui") {
    return;
  }

  // renderWidget returns undefined when a row would be wasted (no list, or a
  // finished one); clearing on undefined is what keeps the editor unadorned
  // outside of active work.
  if (renderWidget(todos, 80, identity) === undefined) {
    ctx.ui.setWidget(WIDGET_ID, undefined);

    return;
  }

  ctx.ui.setWidget(WIDGET_ID, (_tui, theme) => ({
    render: (width: number) => renderWidget(todos, width, theme) ?? [],
    invalidate: () => {},
  }));
}

/**
 * A theme stand-in for the one place a render happens outside pi's callback:
 * the emptiness check above, where only the shape of the result matters.
 */
const identity = { fg: (_c: string, t: string) => t, bold: (t: string) => t };

class TodoOverlay {
  private cached?: string[];
  private cachedWidth?: number;

  constructor(
    private readonly todos: readonly Todo[],
    private readonly theme: Theme,
    private readonly onClose: () => void,
  ) {}

  handleInput(data: string): void {
    if (matchesKey(data, Key.escape) || matchesKey(data, "ctrl+c")) {
      this.onClose();
    }
  }

  render(width: number): string[] {
    if (this.cached && this.cachedWidth === width) {
      return this.cached;
    }

    this.cached = renderOverlay(this.todos, width, this.theme);
    this.cachedWidth = width;

    return this.cached;
  }

  invalidate(): void {
    this.cached = undefined;
    this.cachedWidth = undefined;
  }
}

export default function (pi: ExtensionAPI) {
  // Mirrors the branch rather than owning the list. Every read that matters
  // re-derives from the session, so this is a cache for the widget and the
  // overlay, not a source of truth.
  let todos: Todo[] = [];

  const sync = (ctx: ExtensionContext) => {
    todos = reconstruct(ctx.sessionManager.getBranch(), TOOL_NAME);
    showWidget(ctx, todos);
  };

  // Rebuild whenever the branch changes underfoot. session_tree fires for
  // /tree navigation and forking, which is exactly when a list carried over
  // from the old branch would be wrong.
  pi.on("session_start", async (_event, ctx) => sync(ctx));
  pi.on("session_tree", async (_event, ctx) => sync(ctx));

  pi.registerTool({
    name: TOOL_NAME,
    label: "Todo",
    description:
      "Create and update the task list for the current session. Send the complete list every call; it replaces the previous one.",
    parameters: TodoWriteParams,
    promptGuidelines: [
      "Use todo_write for any task needing three or more steps, and update it as you go: mark an item in_progress before starting it and completed the moment it is done.",
      "Keep exactly one todo_write item in_progress at a time, and skip the tool entirely for single-step or purely conversational requests.",
    ],

    async execute(_toolCallId, params, _signal, _onUpdate, ctx): Promise<AgentToolResult<TodoDetails>> {
      const result = validate(params.todos);

      if (!result.ok) {
        // Thrown rather than returned: pi sets isError on a throw, which is
        // what tells the model the write did not land. A returned value would
        // read as success no matter what it said.
        throw new Error(`Invalid todo list: ${result.error}`);
      }

      todos = result.todos;
      showWidget(ctx, todos);

      return {
        content: [{ type: "text", text: summarize(todos) }],
        // The list on the result is the state at this point in history. It is
        // what reconstruct() replays, so it must be a copy: a later in-place
        // edit of `todos` would otherwise rewrite the past.
        details: { todos: todos.map((todo) => ({ ...todo })) },
      };
    },

    renderCall(args, theme) {
      const count = Array.isArray(args.todos) ? args.todos.length : 0;
      const head = theme.fg("toolTitle", theme.bold("todo "));

      if (count === 0) {
        return new Text(head + theme.fg("muted", "clear"), 0, 0);
      }

      const active = (args.todos as Todo[]).find((todo) => todo?.status === "in_progress");

      return new Text(
        head + theme.fg("muted", active ? active.activeForm : `${count} tasks`),
        0,
        0,
      );
    },

    renderResult(result, { expanded }, theme) {
      // A rejected call has no list to draw, so fall back to the text, which
      // is the validation error. Asking for the list rather than for a details
      // object matters: pi stores `details: {}` on a throw, and reaching
      // through that for a list that was never written renders undefined.
      const todos = todosFrom(result.details);

      if (!todos) {
        const text = result.content[0];

        return new Text(text?.type === "text" ? text.text : "", 0, 0);
      }

      return {
        render: (width: number) => renderList(todos, width, theme, { expanded }),
        invalidate: () => {},
      };
    },
  });

  pi.registerCommand("todos", {
    description: "Show the current task list",
    handler: async (_args, ctx) => {
      if (ctx.mode !== "tui") {
        ctx.ui.notify("/todos requires interactive mode", "error");

        return;
      }

      // Re-derive rather than trusting the cache: a compaction or a session
      // switch may have moved the branch since the last tool call.
      todos = reconstruct(ctx.sessionManager.getBranch(), TOOL_NAME);

      await ctx.ui.custom<void>((_tui, theme, _kb, done) => new TodoOverlay(todos, theme, done));
    },
  });
}
