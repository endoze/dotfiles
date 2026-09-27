import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import {
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
  SettingsManager,
  createBashToolDefinition,
  createLocalBashOperations,
  getAgentDir,
  truncateTail,
} from "@earendil-works/pi-coding-agent";
import { Key, matchesKey, Text } from "@earendil-works/pi-tui";
import {
  OutputTail,
  type TailTruncator,
} from "./background-bash/output.ts";
import {
  BackgroundBashRuntime,
  type BackgroundCompletion,
} from "./background-bash/runtime.ts";

const COMPLETION_TYPE = "background-bash-completion";

const truncateWithPi: TailTruncator = (content) => {
  const result = truncateTail(content, {
    maxBytes: DEFAULT_MAX_BYTES,
    maxLines: DEFAULT_MAX_LINES,
  });
  return { content: result.content, truncated: result.truncated };
};

const duration = (milliseconds: number): string =>
  milliseconds < 1_000
    ? `${milliseconds}ms`
    : `${(milliseconds / 1_000).toFixed(1)}s`;

function completionText(completion: BackgroundCompletion): string {
  const outcome =
    completion.status === "completed"
      ? "finished successfully"
      : completion.status === "cancelled"
        ? "was cancelled"
        : `failed${
            completion.exitCode === undefined
              ? ""
              : ` with exit code ${completion.exitCode}`
          }`;

  return [
    `[background bash #${completion.id}] ${outcome} after ${duration(completion.durationMs)}.`,
    `command: ${completion.command}`,
    `cwd: ${completion.cwd}`,
    ...(completion.error ? [`error: ${completion.error}`] : []),
    "",
    "--- output (tail) ---",
    completion.output,
  ].join("\n");
}

export default function (pi: ExtensionAPI) {
  let sessionContext: ExtensionContext | undefined;
  let unsubscribeInput: (() => void) | undefined;

  const runtime = new BackgroundBashRuntime(
    (completion) => {
      const ctx = sessionContext;
      if (!ctx) return;

      const succeeded = completion.status === "completed";
      try {
        ctx.ui.notify(
          `Background bash #${completion.id} ${
            succeeded ? "finished" : completion.status
          }`,
          succeeded ? "info" : "warning",
        );
      } catch {
        // Lifecycle state is already final. A stale UI must not crash Pi.
      }

      try {
        pi.sendMessage(
          {
            customType: COMPLETION_TYPE,
            content: completionText(completion),
            display: true,
            details: completion,
          },
          { triggerTurn: false },
        );
      } catch {
        // Shutdown invalidates the extension API after delivery is suppressed.
      }
    },
    () => new OutputTail(truncateWithPi),
  );

  const publicDefinition = createBashToolDefinition(process.cwd());
  pi.registerTool({
    ...publicDefinition,
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const settings = SettingsManager.create(ctx.cwd, getAgentDir(), {
        projectTrusted: ctx.isProjectTrusted(),
      });
      const shellPath = settings.getShellPath();
      const commandPrefix = settings.getShellCommandPrefix();
      const invocation = runtime.createInvocation(
        createLocalBashOperations({ shellPath }),
      );
      const native = createBashToolDefinition(ctx.cwd, {
        commandPrefix,
        shellPath,
        operations: invocation.operations,
      });
      const result = await native.execute(
        toolCallId,
        params,
        signal,
        onUpdate,
        ctx,
      );

      return invocation.wasDetached()
        ? { ...result, terminate: true }
        : result;
    },
  });

  pi.registerMessageRenderer(
    COMPLETION_TYPE,
    (message, { expanded }, theme) => {
      const details = message.details as BackgroundCompletion | undefined;
      const status = details?.status ?? "failed";
      const color = status === "completed" ? "success" : "error";
      const heading = details
        ? `${status === "completed" ? "✓" : "✗"} bash #${details.id} ${status}`
        : "background bash completion";
      const text = expanded
        ? `${heading}\n${String(message.content)}`
        : heading;
      return new Text(theme.fg(color, text), 0, 0);
    },
  );

  pi.on("session_start", (_event, ctx) => {
    sessionContext = ctx;
    unsubscribeInput?.();
    if (ctx.mode !== "tui") return;

    unsubscribeInput = ctx.ui.onTerminalInput((data) => {
      if (!matchesKey(data, Key.ctrl("b"))) return undefined;
      const ids = runtime.detachAll();
      if (ids.length === 0) return undefined;

      ctx.ui.notify(
        `Bash ${ids.map((id) => `#${id}`).join(", ")} moved to background`,
        "info",
      );
      return { consume: true };
    });
  });

  pi.on("session_shutdown", async () => {
    unsubscribeInput?.();
    unsubscribeInput = undefined;
    await runtime.shutdown();
    sessionContext = undefined;
  });
}
