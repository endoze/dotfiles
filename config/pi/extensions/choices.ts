// Registers `ask`, a tool that puts multiple-choice questions on screen and
// returns what the user picked. pi auto-loads ~/.pi/agent/extensions/*.ts,
// which is a symlink to config/pi/extensions in this repo, so no settings.json
// entry is needed. The choices/ subdirectory is not auto-loaded: pi descends
// into a subdirectory only for index.ts, index.js, or a package.json declaring
// pi.extensions, and that directory has none.

import type {
  AgentToolResult,
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Editor, type EditorTheme, Key, matchesKey, Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import type { Question } from "./choices/rows.ts";
import { render } from "./choices/render.ts";
import { blockedTitle, sessionTitle } from "./choices/title.ts";
import {
  closeFreeform,
  createState,
  handleKey,
  submitFreeform,
  type Keypress,
  type Outcome,
} from "./choices/state.ts";

const OptionSchema = Type.Object({
  value: Type.String({ description: "Value returned when this option is chosen" }),
  label: Type.String({ description: "Display label" }),
  description: Type.Optional(Type.String({ description: "Optional line under the label" })),
});

const QuestionSchema = Type.Object({
  id: Type.String({ description: "Stable key for this question's answer" }),
  prompt: Type.String({ description: "The question text" }),
  label: Type.Optional(
    Type.String({
      description:
        "Short name for the tab bar, e.g. 'Scope' or 'Priority'. Defaults to Q1, Q2, Q3. Ignored when asking a single question.",
    }),
  ),
  options: Type.Array(OptionSchema, { description: "Options to choose from" }),
  multiple: Type.Optional(
    Type.Boolean({ description: "Select all that apply. Defaults to false." }),
  ),
  allowOther: Type.Optional(
    Type.Boolean({
      description:
        "Offer a freeform 'Type something.' row. Defaults to true for a single question, false in a batch.",
    }),
  ),
});

const AskParams = Type.Object({
  questions: Type.Array(QuestionSchema, { description: "One or more questions to ask" }),
});

interface AskDetails {
  outcome: string;
  answers?: { id: string; values: string[]; wasCustom: boolean }[];
}

// Raw bytes to a Keypress. Kept here so the state machine stays free of
// terminal concerns and remains testable without one.
function decode(data: string): Keypress | null {
  if (matchesKey(data, Key.up)) return { name: "up" };
  if (matchesKey(data, Key.down)) return { name: "down" };
  if (matchesKey(data, Key.left)) return { name: "left" };
  if (matchesKey(data, Key.right)) return { name: "right" };

  // Tab and Shift-Tab are the second way to move between questions, per the
  // spec keymap. They collapse onto the same two directions the arrows use, so
  // the state machine never learns there are two bindings. Shift-Tab must be
  // tested before Tab: some terminals encode it as a Tab with a modifier, and
  // the looser Tab match would swallow it.
  //
  // "shift+tab" is a literal because the Key constant has no shiftTab member:
  // it exposes `tab`, and matchesKey takes modifier strings of this form.
  if (matchesKey(data, "shift+tab")) return { name: "left" };
  if (matchesKey(data, Key.tab)) return { name: "right" };

  if (matchesKey(data, Key.enter)) return { name: "enter" };
  if (matchesKey(data, Key.escape)) return { name: "escape" };
  if (data === " ") return { name: "space" };

  if (/^[1-9]$/.test(data)) {
    return { name: "digit", digit: Number(data) };
  }

  return null;
}

function summarize(outcome: Outcome, questions: Question[]): string {
  if (outcome.kind === "cancelled") {
    return "User cancelled the questions.";
  }

  const lines = outcome.answers.map((answer) => {
    const question = questions.find((q) => q.id === answer.id);
    const labels = answer.values.map(
      (value) => question?.options.find((o) => o.value === value)?.label ?? value,
    );

    return `${question?.prompt ?? answer.id}: ${labels.join(", ")}`;
  });

  if (outcome.kind === "chat") {
    const asked = questions.find((q) => q.id === outcome.questionId);

    return [
      "User wants to discuss rather than pick an option.",
      `They stepped out at: ${asked?.prompt ?? outcome.questionId}`,
      ...(lines.length ? ["Answers so far:", ...lines] : []),
    ].join("\n");
  }

  return lines.length ? lines.join("\n") : "User submitted no answers.";
}

export default function (pi: ExtensionAPI) {
  // True while a question is on screen. session_shutdown is the only path that
  // can fire between the marker going up and the finally taking it down, so
  // this keeps that handler from stamping a title on a session that never
  // asked anything.
  let marked = false;

  pi.registerTool({
    name: "ask",
    label: "Ask",
    description:
      "Ask the user one or more multiple-choice questions and wait for their answers. Use when a decision is needed to proceed.",
    parameters: AskParams,
    executionMode: "sequential",

    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      if (ctx.mode !== "tui") {
        return {
          content: [
            { type: "text", text: "Error: questions need a TUI (running in non-interactive mode)" },
          ],
          details: { outcome: "unavailable" },
        };
      }

      const raw = params.questions ?? [];

      if (raw.length === 0 || raw.some((q) => q.options.length === 0)) {
        return {
          content: [{ type: "text", text: "Error: every question needs at least one option" }],
          details: { outcome: "invalid" },
        };
      }

      // allowOther defaults to true only when there is a single question: that
      // is the case where the option set is a guess and free text is the
      // escape valve. In a batch it is the model's call.
      const questions: Question[] = raw.map((q, i) => ({
        id: q.id,
        prompt: q.prompt,
        label: q.label ?? `Q${i + 1}`,
        options: q.options,
        multiple: q.multiple ?? false,
        allowOther: q.allowOther ?? raw.length === 1,
      }));

      // Captured before the marker goes up: pi offers no way to read the
      // current title back, so the restore path needs the unmarked form kept
      // in hand.
      const title = sessionTitle(
        ctx.sessionManager.getSessionName(),
        ctx.sessionManager.getCwd(),
      );

      // pi considers the turn to still be running for as long as this tool is
      // awaiting, so the working indicator animates the entire time the
      // overlay is up. Every tick repaints in place, and repainting in place
      // snaps the terminal viewport to the bottom, which makes it impossible
      // to scroll back through history while a question is on screen. Nothing
      // is actually progressing here (we are waiting on a human), so hide it
      // and restore it when the overlay closes.
      //
      // Confirmed to be the cause rather than overlay rendering in general:
      // /model opens a comparable overlay with no tool in flight, and
      // scrollback behaves normally there.

      ctx.ui.setWorkingVisible(false);
      ctx.ui.setWorkingIndicator({ frames: [] });

      // herdr reads the OSC title to classify a pane, and hiding the indicator
      // above also removes the "Working..." literal its working rule keys on.
      // Without the marker an unanswered question reads as idle, which is the
      // opposite of true.
      ctx.ui.setTitle(blockedTitle(
        ctx.sessionManager.getSessionName(),
        ctx.sessionManager.getCwd(),
      ));
      marked = true;

      try {
        return await askQuestions(ctx, questions);
      } finally {
        // Restore in a finally so a throw or a cancel cannot leave the session
        // permanently without its indicator, or permanently looking stuck.
        marked = false;
        ctx.ui.setTitle(title);
        ctx.ui.setWorkingIndicator();
        ctx.ui.setWorkingVisible(true);
      }
    },

    renderCall(args, theme) {
      const questions = Array.isArray(args.questions) ? args.questions : [];
      const head = theme.fg("toolTitle", theme.bold("ask "));

      if (questions.length === 1) {
        return new Text(head + theme.fg("muted", questions[0].prompt), 0, 0);
      }

      return new Text(head + theme.fg("muted", `${questions.length} questions`), 0, 0);
    },

    renderResult(result, _options, theme) {
      const details = result.details as { outcome?: string } | undefined;

      if (details?.outcome === "cancelled") {
        return new Text(theme.fg("warning", "Cancelled"), 0, 0);
      }

      if (details?.outcome === "chat") {
        return new Text(theme.fg("warning", "→ wants to discuss"), 0, 0);
      }

      const text = result.content[0];

      return new Text(
        theme.fg("success", "✓ ") + theme.fg("accent", text?.type === "text" ? text.text : ""),
        0,
        0,
      );
    },
  });

  // herdr keeps the last title it saw rather than expiring it, so quitting with
  // a question open would leave the pane looking blocked indefinitely. This
  // covers quit, reload, new, resume, and fork; a hard kill is beyond reach.
  pi.on("session_shutdown", async (_event, ctx) => {
    if (!marked) {
      return;
    }

    marked = false;
    ctx.ui.setTitle(
      sessionTitle(ctx.sessionManager.getSessionName(), ctx.sessionManager.getCwd()),
    );
  });
}


// The overlay itself, split out so the indicator suppression above reads as a
// single try/finally rather than wrapping the whole of the UI wiring.
async function askQuestions(
  ctx: ExtensionContext,
  questions: Question[],
): Promise<AgentToolResult<AskDetails>> {
  const outcome = await ctx.ui.custom<Outcome>((tui, theme, _kb, done) => {
    let state = createState(questions);
    let cached: string[] | undefined;

    const refresh = () => {
      cached = undefined;
      tui.requestRender();
    };

    // pi's Editor, so freeform answers get cursor movement, word deletion,
    // paste, and history rather than the raw character buffer this used to
    // keep in the state machine.
    const editorTheme: EditorTheme = {
      borderColor: (s) => theme.fg("accent", s),
      selectList: {
        selectedPrefix: (t) => theme.fg("accent", t),
        selectedText: (t) => theme.fg("accent", t),
        description: (t) => theme.fg("muted", t),
        scrollInfo: (t) => theme.fg("dim", t),
        noMatch: (t) => theme.fg("warning", t),
      },
    };
    const editor = new Editor(tui, editorTheme);

    const apply = (result: { state: typeof state } | { done: Outcome }) => {
      if ("done" in result) {
        done(result.done);

        return;
      }

      state = result.state;
      refresh();
    };

    editor.onSubmit = (value: string) => {
      apply(submitFreeform(state, value));
      editor.setText("");
    };

    return {
      render: (width: number) => {
        // Indent the editor under the "Your answer:" label, and keep it inside
        // the frame.
        cached ??= render(
          state,
          width,
          theme,
          state.freeform ? editor.render(Math.max(1, width - 4)).map((line) => `  ${line}`) : [],
        );

        return cached;
      },
      invalidate: () => {
        cached = undefined;
        editor.invalidate();
      },
      handleInput: (data: string) => {
        // While the editor is open it owns every key except Escape, which
        // backs out to the list. Enter reaches it as onSubmit.
        if (state.freeform) {
          if (matchesKey(data, Key.escape)) {
            editor.setText("");
            state = closeFreeform(state);
            refresh();

            return;
          }

          editor.handleInput(data);
          refresh();

          return;
        }

        const key = decode(data);

        if (key === null) {
          return;
        }

        apply(handleKey(state, key));
      },
    };
  });

  return {
    content: [{ type: "text", text: summarize(outcome, questions) }],
    details: { outcome: outcome.kind, answers: "answers" in outcome ? outcome.answers : [] },
  };
}
