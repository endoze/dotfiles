import assert from "node:assert/strict";
import { test } from "node:test";
import type { BashOperations } from "@earendil-works/pi-coding-agent";
import {
  BackgroundBashRuntime,
  type BackgroundCompletion,
} from "./runtime.ts";

type ExecResult = Awaited<ReturnType<BashOperations["exec"]>>;
type ExecOptions = Parameters<BashOperations["exec"]>[2];

function deferred<T>() {
  let resolve!: (value: T) => void;
  let reject!: (error: unknown) => void;
  const promise = new Promise<T>((yes, no) => {
    resolve = yes;
    reject = no;
  });
  return { promise, resolve, reject };
}

function controlledOperations() {
  const result = deferred<ExecResult>();
  let options: ExecOptions | undefined;

  const operations: BashOperations = {
    exec: async (_command, _cwd, nextOptions) => {
      options = nextOptions;
      return result.promise;
    },
  };

  return {
    operations,
    emit(text: string) {
      assert.ok(options, "exec must start before output is emitted");
      options.onData(Buffer.from(text));
    },
    finish(exitCode: number | null) {
      result.resolve({ exitCode } as ExecResult);
    },
    fail(error: unknown) {
      result.reject(error);
    },
    childSignal(): AbortSignal {
      assert.ok(options?.signal, "exec must start with a child signal");
      return options.signal;
    },
  };
}

const run = (
  runtime: BackgroundBashRuntime,
  base: BashOperations,
  parent: AbortController,
  forwarded: string[],
) => {
  const invocation = runtime.createInvocation(base);
  const pending = invocation.operations.exec("npm test", "/repo", {
    signal: parent.signal,
    onData: (data) => forwarded.push(Buffer.from(data).toString("utf8")),
  });
  return { invocation, pending };
};

test("foreground execution forwards output and returns the native result", async () => {
  const completions: BackgroundCompletion[] = [];
  const runtime = new BackgroundBashRuntime((value) => completions.push(value));
  const controlled = controlledOperations();
  const forwarded: string[] = [];
  const { invocation, pending } = run(
    runtime,
    controlled.operations,
    new AbortController(),
    forwarded,
  );

  controlled.emit("running\n");
  controlled.finish(0);

  assert.equal((await pending).exitCode, 0);
  assert.deepEqual(forwarded, ["running\n"]);
  assert.equal(invocation.wasDetached(), false);
  assert.deepEqual(completions, []);
});

test("detach resolves the tool call but the same operation keeps running", async () => {
  const completed = deferred<BackgroundCompletion>();
  const runtime = new BackgroundBashRuntime(completed.resolve);
  const controlled = controlledOperations();
  const parent = new AbortController();
  const forwarded: string[] = [];
  const { invocation, pending } = run(
    runtime,
    controlled.operations,
    parent,
    forwarded,
  );

  controlled.emit("before\n");
  assert.deepEqual(runtime.detachAll(), [1]);
  assert.equal((await pending).exitCode, 0);
  assert.equal(invocation.wasDetached(), true);
  assert.match(forwarded.join(""), /still running in the background/);

  parent.abort();
  assert.equal(controlled.childSignal().aborted, false);

  controlled.emit("after\n");
  controlled.finish(0);
  const completion = await completed.promise;

  assert.equal(completion.id, 1);
  assert.equal(completion.status, "completed");
  assert.equal(completion.exitCode, 0);
  assert.match(completion.output, /before\nafter/);
  assert.equal(forwarded.join("").includes("after"), false);
});

test("parent abort reaches a foreground operation", async () => {
  const runtime = new BackgroundBashRuntime(() =>
    assert.fail("no completion expected"),
  );
  const controlled = controlledOperations();
  const parent = new AbortController();
  const { pending } = run(runtime, controlled.operations, parent, []);

  parent.abort();
  assert.equal(controlled.childSignal().aborted, true);
  controlled.fail(new DOMException("aborted", "AbortError"));
  await assert.rejects(pending, /aborted/);
});

test("detach refuses a foreground operation whose parent already aborted", async () => {
  const runtime = new BackgroundBashRuntime(() =>
    assert.fail("no completion expected"),
  );
  const controlled = controlledOperations();
  const parent = new AbortController();
  const { invocation, pending } = run(
    runtime,
    controlled.operations,
    parent,
    [],
  );

  parent.abort();
  assert.deepEqual(runtime.detachAll(), []);
  assert.equal(invocation.wasDetached(), false);
  controlled.fail(new DOMException("aborted", "AbortError"));
  await assert.rejects(pending, /aborted/);
});

test("a pre-aborted parent starts the native operation aborted", async () => {
  const runtime = new BackgroundBashRuntime(() =>
    assert.fail("no completion expected"),
  );
  const controlled = controlledOperations();
  const parent = new AbortController();
  parent.abort();
  const { pending } = run(runtime, controlled.operations, parent, []);

  assert.equal(controlled.childSignal().aborted, true);
  controlled.fail(new DOMException("aborted", "AbortError"));
  await assert.rejects(pending, /aborted/);
});

test("a synchronous spawn failure stays on the foreground error path", async () => {
  const runtime = new BackgroundBashRuntime(() =>
    assert.fail("no completion expected"),
  );
  const operations: BashOperations = {
    exec: () => {
      throw new Error("spawn failed");
    },
  };
  const invocation = runtime.createInvocation(operations);
  const pending = invocation.operations.exec("missing-command", "/repo", {
    signal: new AbortController().signal,
    onData: () => {},
  });

  await assert.rejects(pending, /spawn failed/);
  assert.equal(invocation.wasDetached(), false);
  assert.deepEqual(runtime.detachAll(), []);
});

test("a detached nonzero exit emits one failed completion", async () => {
  const completions: BackgroundCompletion[] = [];
  const runtime = new BackgroundBashRuntime((value) => completions.push(value));
  const controlled = controlledOperations();
  const { pending } = run(
    runtime,
    controlled.operations,
    new AbortController(),
    [],
  );

  runtime.detachAll();
  await pending;
  controlled.finish(7);
  await new Promise<void>((resolve) => setImmediate(resolve));
  controlled.finish(7);
  await new Promise<void>((resolve) => setImmediate(resolve));

  assert.equal(completions.length, 1);
  assert.equal(completions[0].status, "failed");
  assert.equal(completions[0].exitCode, 7);
});

test("a detached null exit reports cancellation", async () => {
  const completions: BackgroundCompletion[] = [];
  const runtime = new BackgroundBashRuntime((value) => completions.push(value));
  const controlled = controlledOperations();
  const { pending } = run(
    runtime,
    controlled.operations,
    new AbortController(),
    [],
  );

  runtime.detachAll();
  await pending;
  controlled.finish(null);
  await new Promise<void>((resolve) => setImmediate(resolve));

  assert.equal(completions.length, 1);
  assert.equal(completions[0].status, "cancelled");
  assert.equal(completions[0].exitCode, null);
});

test("one detach backgrounds every concurrent foreground operation", async () => {
  const runtime = new BackgroundBashRuntime(() => {});
  const first = controlledOperations();
  const second = controlledOperations();
  const one = run(runtime, first.operations, new AbortController(), []);
  const two = run(runtime, second.operations, new AbortController(), []);

  assert.deepEqual(runtime.detachAll(), [1, 2]);
  assert.equal((await one.pending).exitCode, 0);
  assert.equal((await two.pending).exitCode, 0);
  assert.equal(one.invocation.wasDetached(), true);
  assert.equal(two.invocation.wasDetached(), true);

  first.finish(0);
  second.finish(0);
});

test("shutdown aborts detached children and suppresses completion", async () => {
  const completions: BackgroundCompletion[] = [];
  const runtime = new BackgroundBashRuntime((value) => completions.push(value));
  const controlled = controlledOperations();
  const { pending } = run(
    runtime,
    controlled.operations,
    new AbortController(),
    [],
  );

  runtime.detachAll();
  await pending;
  const shutdown = runtime.shutdown();
  assert.equal(controlled.childSignal().aborted, true);

  controlled.fail(new DOMException("aborted", "AbortError"));
  await shutdown;
  assert.deepEqual(completions, []);
});

test("a command that settles before detach stays foreground", async () => {
  const runtime = new BackgroundBashRuntime(() => {});
  const controlled = controlledOperations();
  const { invocation, pending } = run(
    runtime,
    controlled.operations,
    new AbortController(),
    [],
  );

  controlled.finish(0);
  await pending;

  assert.deepEqual(runtime.detachAll(), []);
  assert.equal(invocation.wasDetached(), false);
});
