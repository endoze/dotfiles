// Custom footer skeleton.
//
// Discovery: pi auto-loads ~/.pi/agent/extensions/*.ts, which is a symlink to
// config/pi/extensions in this repo (see modules/home/common/pi.nix). No
// settings.json entry is needed. Extensions load via jiti, so this .ts file
// runs as-is with no build step.

import type {
  ExtensionAPI,
  ThemeColor,
  ExtensionContext,
  SessionEntry,
} from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

const JJ_REFRESH_MS = 2000;
const JJ_TIMEOUT_MS = 2000;
const CONTEXT_BAR_WIDTH = 10;

type ColorName =
  | "black"
  | "red"
  | "green"
  | "yellow"
  | "blue"
  | "magenta"
  | "white"
  | "brightBlack"
  | "brightRed"
  | "brightGreen"
  | "brightYellow"
  | "brightBlue"
  | "brightMagenta"
  | "cyan"
  | "brightCyan"
  | "brightWhite"
  | "orange"
  | "default";

const COLOR_MAP: Record<ColorName, ThemeColor> = {
  black: "thinkingOff",
  red: "error",
  green: "success",
  yellow: "warning",
  blue: "border",
  magenta: "customMessageLabel",
  white: "muted",
  brightBlack: "dim",
  brightRed: "toolDiffRemoved",
  brightGreen: "toolDiffAdded",
  brightYellow: "mdHeading",
  brightBlue: "mdLink",
  brightMagenta: "thinkingHigh",
  cyan: "accent",
  brightCyan: "borderAccent",
  brightWhite: "toolTitle",
  default: "text",
  orange: "syntaxNumber",
};

const usageOf = (entry: SessionEntry) => {
  if (entry.type === "message" && entry.message.role === "assistant") {
    return entry.message.usage;
  }

  if (entry.type === "message" && entry.message.role === "toolResult") {
    return entry.message.usage;
  }

  if (entry.type === "branch_summary" || entry.type === "compaction") {
    return entry.usage;
  }

  return undefined;
};

export default function (pi: ExtensionAPI) {
  let jj = "";
  let timer: ReturnType<typeof setInterval> | null = null;
  let inFlight = false;
  let startedAt = Date.now();
  let elapsedMs = 0;
  let costTotal = 0;

  // Set by the footer factory, which is the only place tui is handed to us.
  let requestRender: () => void = () => {};

  // Resolves true only when the cached value changed, so the poll repaints on a
  // real difference instead of every tick.
  async function getJjStatus(ctx: ExtensionContext): Promise<boolean> {
    if (inFlight) {
      return false;
    }

    inFlight = true;

    try {
      const result = await pi.exec(
        "jj-starship",
        [
          "prompt",
          "--no-color",
          "--no-jj-prefix",
          "--no-git-prefix",
          "--bookmarks-display-limit",
          "1",
        ],
        { cwd: ctx.cwd, timeout: JJ_TIMEOUT_MS },
      );

      // A timeout reports code 0 with killed set, since exec falls back to 0
      // when the child dies on a signal. Keep the last known value rather than
      // reading a kill as an empty prompt.
      if (result.killed) {
        return false;
      }

      // Nonzero is the ordinary outside-a-repo case, not a failure to report.
      const next = result.code === 0 ? result.stdout.trim() : "";

      if (next === jj) {
        return false;
      }

      jj = next;

      return true;
    } catch {
      // jj-starship is not on PATH, or the spawn itself failed.
      return false;
    } finally {
      inFlight = false;
    }
  }

  // Recomputed at turn end alongside the duration, so cost holds still until a
  // turn lands. Doing it in render() instead would walk the whole session on
  // every keystroke, and getEntries() allocates a fresh array each call.
  function refreshCost(ctx: ExtensionContext): void {
    costTotal = ctx.sessionManager
      .getEntries()
      .reduce((total, entry) => total + (usageOf(entry)?.cost.total ?? 0), 0);
  }

  function stopTimer(): void {
    if (timer) {
      clearInterval(timer);
      timer = null;
    }
  }

  pi.on("session_start", async (_event, ctx) => {
    const header = ctx.sessionManager.getHeader();
    startedAt = header ? Date.parse(header.timestamp) : Date.now();

    // Duration is wall time from session creation to the end of the last turn,
    // resume gaps included, so seed it from the transcript rather than carrying
    // whatever the previous session left behind. A fresh session has no entries
    // and starts at zero; a resumed one keeps the time it already accumulated.
    // A fork copies pre-fork entries under a new header, hence the clamp.
    const lastEntry = ctx.sessionManager.getEntries().at(-1);
    elapsedMs = lastEntry
      ? Math.max(0, Date.parse(lastEntry.timestamp) - startedAt)
      : 0;

    refreshCost(ctx);
    await getJjStatus(ctx);

    const applyColor = (color: ColorName, value: string): string =>
      ctx.ui.theme.fg(COLOR_MAP[color], value);

    const separator = (): string => {
      return applyColor("brightBlack", " | ");
    };

    const modelName = (): string => {
      // Empty when the model is unknown so line() drops the segment instead of
      // painting the string "undefined".
      return ctx.model ? applyColor("cyan", ctx.model.name) : "";
    };

    const jjStatus = (): string => {
      return jj === "" ? "" : applyColor("orange", jj);
    };

    const sessionContextBar = (): string => {
      const unusedCharacter = "░";
      const usedCharacter = "▓";
      const percent = ctx.getContextUsage()?.percent ?? null;

      // null is unknown, not empty: right after a compaction the token count is
      // unreadable until the next assistant reply.
      if (percent === null) {
        return applyColor(
          "brightBlack",
          `${unusedCharacter.repeat(CONTEXT_BAR_WIDTH)} ?%`,
        );
      }

      // Round once so the blocks, the color, and the label always agree. Clamp
      // the block count separately so an over-full context still prints its real
      // percentage without asking repeat() for a negative count.
      const rounded = Math.round(percent);
      const clamped = Math.min(100, Math.max(0, rounded));
      const usedCount = Math.round((clamped * CONTEXT_BAR_WIDTH) / 100);

      const barColor: ColorName =
        clamped <= 40 ? "green" : clamped <= 60 ? "yellow" : "red";

      const bar =
        usedCharacter.repeat(usedCount) +
        unusedCharacter.repeat(CONTEXT_BAR_WIDTH - usedCount);

      return applyColor(barColor, `${bar} ${rounded}%`);
    };

    const sessionCost = (): string => {
      return applyColor("green", `$${costTotal.toFixed(2)}`);
    };

    const sessionDuration = (): string => {
      const elapsedSec = Math.floor(elapsedMs / 1000);
      const mins = Math.floor(elapsedSec / 60);
      const secs = elapsedSec % 60;

      return applyColor("magenta", `${mins}m ${secs}s`);
    };

    const line = (components: string[], width: number): string => {
      const body = components
        .filter((component) => component !== "")
        .join(separator());

      return truncateToWidth(" " + body, width);
    };

    ctx.ui.setFooter((tui) => {
      requestRender = () => tui.requestRender();

      return {
        render(width: number): string[] {
          return [
            line([modelName(), jjStatus()], width),
            line(
              [sessionContextBar(), sessionCost(), sessionDuration()],
              width,
            ),
          ];
        },
        invalidate() {},
        // No dispose: the poll's lifetime is the session, which
        // session_shutdown owns. Disposing here would kill polling for good if
        // another extension ever installed its own footer.
      };
    });

    stopTimer();

    timer = setInterval(() => {
      void getJjStatus(ctx).then((changed) => {
        if (changed) {
          requestRender();
        }
      });
    }, JJ_REFRESH_MS);
  });

  pi.on("turn_end", (_event, ctx) => {
    elapsedMs = Date.now() - startedAt;
    refreshCost(ctx);
  });

  pi.on("session_shutdown", () => {
    stopTimer();
  });
}
