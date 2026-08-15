import type { BashOperations } from "@earendil-works/pi-coding-agent";
import { OutputTail } from "./output.ts";

type ExecResult = Awaited<ReturnType<BashOperations["exec"]>>;
type ExecOptions = Parameters<BashOperations["exec"]>[2];
type ExecOutcome =
  | { ok: true; result: ExecResult }
  | { ok: false; error: unknown };

export type CompletionStatus = "completed" | "failed" | "cancelled";

export interface BackgroundCompletion {
  id: number;
  command: string;
  cwd: string;
  durationMs: number;
  status: CompletionStatus;
  exitCode: number | null | undefined;
  error?: string;
  output: string;
}

export interface InvocationHandle {
  operations: BashOperations;
  wasDetached(): boolean;
}

interface Job {
  id: number;
  command: string;
  cwd: string;
  startedAt: number;
  state: "foreground" | "detached" | "settled";
  controller: AbortController;
  output: OutputTail;
  detach(): boolean;
}

const errorText = (error: unknown): string =>
  error instanceof Error ? error.message : String(error);

const isAbort = (error: unknown): boolean =>
  error instanceof Error && error.name === "AbortError";

const backgroundNote = (id: number): string =>
  `\n\n[pi] Command moved to the background (job #${id}). It is still running ` +
  "in the background; pi will report its exit code and output when it finishes. " +
  "Do not re-run it.";

export class BackgroundBashRuntime {
  private nextId = 1;
  private readonly foreground = new Map<number, Job>();
  private readonly detached = new Map<number, Job>();
  private readonly pending = new Set<Promise<void>>();
  private readonly onCompletion: (completion: BackgroundCompletion) => void;
  private readonly createOutput: () => OutputTail;
  private shuttingDown = false;

  constructor(
    onCompletion: (completion: BackgroundCompletion) => void,
    createOutput: () => OutputTail = () => new OutputTail(),
  ) {
    this.onCompletion = onCompletion;
    this.createOutput = createOutput;
  }

  createInvocation(base: BashOperations): InvocationHandle {
    let invocationDetached = false;

    const operations: BashOperations = {
      exec: (command, cwd, options) => {
        const id = this.nextId++;
        const output = this.createOutput();
        const controller = new AbortController();
        let resolveOuter!: (result: ExecResult) => void;
        let rejectOuter!: (error: unknown) => void;

        const outer = new Promise<ExecResult>((resolve, reject) => {
          resolveOuter = resolve;
          rejectOuter = reject;
        });

        const forwardAbort = () => controller.abort();
        if (options.signal?.aborted) controller.abort();
        else {
          options.signal?.addEventListener("abort", forwardAbort, { once: true });
        }

        const job: Job = {
          id,
          command,
          cwd,
          startedAt: Date.now(),
          state: "foreground",
          controller,
          output,
          detach: () => {
            if (job.state !== "foreground" || controller.signal.aborted) {
              return false;
            }
            job.state = "detached";
            invocationDetached = true;
            this.foreground.delete(id);
            this.detached.set(id, job);
            options.signal?.removeEventListener("abort", forwardAbort);
            options.onData(Buffer.from(backgroundNote(id)));
            resolveOuter({ exitCode: 0 } as ExecResult);
            return true;
          },
        };

        this.foreground.set(id, job);

        const settle = (outcome: ExecOutcome): void => {
          if (job.state === "settled") return;
          const previous = job.state;
          job.state = "settled";
          this.foreground.delete(id);
          this.detached.delete(id);
          options.signal?.removeEventListener("abort", forwardAbort);
          output.finish();

          if (previous === "foreground") {
            if (outcome.ok) resolveOuter(outcome.result);
            else rejectOuter(outcome.error);
            return;
          }

          if (this.shuttingDown) return;
          const exitCode = outcome.ok ? outcome.result.exitCode : undefined;
          const status: CompletionStatus = outcome.ok
            ? exitCode === 0
              ? "completed"
              : exitCode === null
                ? "cancelled"
                : "failed"
            : isAbort(outcome.error)
              ? "cancelled"
              : "failed";

          try {
            this.onCompletion({
              id,
              command,
              cwd,
              durationMs: Date.now() - job.startedAt,
              status,
              exitCode,
              error: outcome.ok ? undefined : errorText(outcome.error),
              output: output.format(),
            });
          } catch {
            // The job is settled even when best-effort delivery fails.
          }
        };

        let execution: Promise<ExecResult>;
        try {
          execution = Promise.resolve(
            base.exec(command, cwd, {
              ...options,
              signal: controller.signal,
              onData: (data) => {
                output.append(data);
                if (job.state === "foreground") options.onData(data);
              },
            } satisfies ExecOptions),
          );
        } catch (error) {
          settle({ ok: false, error });
          return outer;
        }

        const pending = execution.then(
          (result) => settle({ ok: true, result }),
          (error) => settle({ ok: false, error }),
        );
        this.pending.add(pending);
        void pending.finally(() => this.pending.delete(pending));

        return outer;
      },
    };

    return {
      operations,
      wasDetached: () => invocationDetached,
    };
  }

  detachAll(): number[] {
    const ids: number[] = [];
    for (const job of [...this.foreground.values()]) {
      if (job.detach()) ids.push(job.id);
    }
    return ids.sort((left, right) => left - right);
  }

  async shutdown(): Promise<void> {
    this.shuttingDown = true;
    for (const job of [...this.foreground.values(), ...this.detached.values()]) {
      job.controller.abort();
    }
    await Promise.allSettled([...this.pending]);
  }
}
