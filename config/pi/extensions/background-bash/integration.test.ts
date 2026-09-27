import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  existsSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  watch,
} from "node:fs";
import { writeFile } from "node:fs/promises";
import { homedir, tmpdir } from "node:os";
import { basename, dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { test, type TestContext } from "node:test";

const here = dirname(fileURLToPath(import.meta.url));
const extensionFile = resolve(here, "..", "background-bash.ts");

function piPackageRoot(): string {
  if (process.env.PI_PACKAGE_DIR) {
    const configured = resolve(process.env.PI_PACKAGE_DIR);
    return configured.endsWith("/dist") ? dirname(configured) : configured;
  }

  const profilePackage = join(
    homedir(),
    ".nix-profile/lib/node_modules/pi-monorepo",
  );
  if (existsSync(join(profilePackage, "package.json"))) return profilePackage;

  throw new Error(
    "Pi package not found. Set PI_PACKAGE_DIR to the public package root.",
  );
}

async function loadPi() {
  const root = piPackageRoot();
  const manifest = JSON.parse(
    readFileSync(join(root, "package.json"), "utf8"),
  ) as { main: string };
  return import(pathToFileURL(resolve(root, manifest.main)).href);
}

async function loadExtension(t: TestContext) {
  const pi = await loadPi();
  const agentDir = mkdtempSync(join(tmpdir(), "pi-background-bash-agent-"));
  t.after(() => rmSync(agentDir, { recursive: true, force: true }));
  const loaded = await pi.discoverAndLoadExtensions(
    [extensionFile],
    process.cwd(),
    agentDir,
  );
  assert.deepEqual(loaded.errors, []);
  const extension = loaded.extensions.find(
    (value: { path: string }) => value.path === extensionFile,
  );
  assert.ok(
    extension,
    `extension not found in ${loaded.extensions.map((value: { path: string }) => value.path)}`,
  );
  return { pi, loaded, extension };
}

type InputResult = { consume?: boolean; data?: string } | undefined;
type InputHandler = (data: string) => InputResult;
type TestToolResult = {
  content: Array<{ type: string; text?: string }>;
  terminate?: boolean;
};

function fakeSessionContext(cwd = process.cwd()) {
  const notices: Array<{ message: string; type: string | undefined }> = [];
  let input: InputHandler | undefined;
  const ctx = {
    cwd,
    mode: "tui",
    isProjectTrusted: () => true,
    ui: {
      notify: (message: string, type?: string) => notices.push({ message, type }),
      onTerminalInput: (handler: InputHandler) => {
        input = handler;
        return () => {
          input = undefined;
        };
      },
    },
  };
  return { ctx, notices, input: () => input };
}

function fakeToolContext(cwd = process.cwd()) {
  return {
    cwd,
    isProjectTrusted: () => true,
    sessionManager: {
      getSessionId: () => "background-bash-integration",
      getSessionFile: () => undefined,
    },
    model: undefined,
    thinkingLevel: "off",
  };
}

function deferred<T>() {
  let resolve!: (value: T) => void;
  let reject!: (error: unknown) => void;
  const promise = new Promise<T>((yes, no) => {
    resolve = yes;
    reject = no;
  });
  return { promise, resolve, reject };
}

async function withDeadline<T>(
  promise: Promise<T>,
  label: string,
  milliseconds = 5_000,
): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  try {
    return await Promise.race([
      promise,
      new Promise<never>((_resolve, reject) => {
        timer = setTimeout(
          () => reject(new Error(`${label} exceeded ${milliseconds}ms`)),
          milliseconds,
        );
      }),
    ]);
  } finally {
    if (timer) clearTimeout(timer);
  }
}

async function waitForPath(path: string): Promise<void> {
  if (existsSync(path)) return;
  await withDeadline(
    new Promise<void>((resolveReady, reject) => {
      const watcher = watch(dirname(path), (event, filename) => {
        if (event === "rename" && filename?.toString() === basename(path)) {
          watcher.close();
          resolveReady();
        }
      });
      watcher.on("error", reject);
      if (existsSync(path)) {
        watcher.close();
        resolveReady();
      }
    }),
    `waiting for ${path}`,
  );
}

const shellQuote = (value: string): string =>
  `'${value.replaceAll("'", `'"'"'`)}'`;

function makeFifo(path: string): void {
  const result = spawnSync("mkfifo", [path], { encoding: "utf8" });
  assert.equal(result.status, 0, result.stderr);
}

async function startedSession(t: TestContext) {
  const loaded = await loadExtension(t);
  const session = fakeSessionContext();
  const sent: Array<{ message: unknown; options: unknown }> = [];
  const delivered = deferred<void>();
  loaded.loaded.runtime.sendMessage = (message: unknown, options: unknown) => {
    sent.push({ message, options });
    delivered.resolve();
  };

  await loaded.extension.handlers.get("session_start")?.[0]?.(
    { type: "session_start", reason: "startup" },
    session.ctx,
  );

  const controller = new AbortController();
  const shutdown = async () => {
    controller.abort();
    await loaded.extension.handlers.get("session_shutdown")?.[0]?.(
      { type: "session_shutdown", reason: "quit" },
      session.ctx,
    );
  };

  return { ...loaded, session, sent, delivered, controller, shutdown };
}

test("loads one Bash override with native schema and renderers", async (t) => {
  const { pi, extension } = await loadExtension(t);
  assert.deepEqual([...extension.tools.keys()], ["bash"]);

  const actual = extension.tools.get("bash")!.definition;
  const native = pi.createBashToolDefinition(process.cwd());
  assert.deepEqual(actual.parameters, native.parameters);
  assert.equal(typeof actual.renderCall, "function");
  assert.equal(typeof actual.renderResult, "function");
});

test("idle Ctrl+B passes through to Pi's editor", async (t) => {
  const { extension } = await loadExtension(t);
  const session = fakeSessionContext();
  await extension.handlers.get("session_start")?.[0]?.(
    { type: "session_start", reason: "startup" },
    session.ctx,
  );

  assert.ok(session.input());
  assert.equal(session.input()!("\x02"), undefined);
});

test("a quick command preserves native Bash output", async (t) => {
  const { pi, extension } = await loadExtension(t);
  const tool = extension.tools.get("bash")!.definition;
  const settings = pi.SettingsManager.create(process.cwd(), pi.getAgentDir(), {
    projectTrusted: true,
  });
  const native = pi.createBashToolDefinition(process.cwd(), {
    shellPath: settings.getShellPath(),
    commandPrefix: settings.getShellCommandPrefix(),
  });
  const signal = new AbortController().signal;
  const ctx = fakeToolContext();

  const actual = await tool.execute(
    "actual",
    { command: "printf background-bash-parity" },
    signal,
    undefined,
    ctx,
  );
  const expected = await native.execute(
    "native",
    { command: "printf background-bash-parity" },
    signal,
    undefined,
    ctx,
  );

  assert.equal(actual.content[0]?.type, "text");
  assert.equal(actual.content[0]?.text, expected.content[0]?.text);
  assert.equal(actual.terminate, undefined);
});

test("Ctrl+B returns the tool call while the exact child continues", async (t) => {
  const fixture = await startedSession(t);
  const root = mkdtempSync(join(tmpdir(), "pi-background-bash-process-"));
  t.after(async () => {
    await fixture.shutdown();
    rmSync(root, { recursive: true, force: true });
  });
  const pidFile = join(root, "pid");
  const releaseFifo = join(root, "release");
  makeFifo(releaseFifo);

  const command = [
    `printf '%s\\n' "$$" > ${shellQuote(pidFile)}`,
    `printf 'before:%s\\n' "$$"`,
    `IFS= read -r _ < ${shellQuote(releaseFifo)}`,
    `printf 'after:%s\\n' "$$"`,
  ].join("; ");

  const tool = fixture.extension.tools.get("bash")!.definition;
  const execution = tool.execute(
    "same-process",
    { command },
    fixture.controller.signal,
    undefined,
    fakeToolContext(root),
  ) as Promise<TestToolResult>;

  await waitForPath(pidFile);
  const pid = readFileSync(pidFile, "utf8").trim();
  assert.deepEqual(fixture.session.input()!("\x02"), { consume: true });

  const handoff = await withDeadline(execution, "Bash handoff", 1_000);
  assert.equal(handoff.terminate, true);
  assert.match(
    handoff.content[0]?.type === "text"
      ? (handoff.content[0].text ?? "")
      : "",
    /still running/,
  );

  await writeFile(releaseFifo, "continue\n");
  await withDeadline(fixture.delivered.promise, "completion message");

  assert.equal(fixture.sent.length, 1);
  const sent = fixture.sent[0] as {
    message: {
      customType: string;
      content: string;
      details: { status: string };
    };
    options: { triggerTurn?: boolean };
  };
  assert.equal(sent.message.customType, "background-bash-completion");
  assert.equal(sent.message.details.status, "completed");
  assert.match(sent.message.content, new RegExp(`before:${pid}`));
  assert.match(sent.message.content, new RegExp(`after:${pid}`));
  assert.deepEqual(sent.options, { triggerTurn: false });
});

test("a detached nonzero exit reports failure without a second tool result", async (t) => {
  const fixture = await startedSession(t);
  const root = mkdtempSync(join(tmpdir(), "pi-background-bash-failure-"));
  t.after(async () => {
    await fixture.shutdown();
    rmSync(root, { recursive: true, force: true });
  });
  const pidFile = join(root, "pid");
  const releaseFifo = join(root, "release");
  makeFifo(releaseFifo);

  const command = [
    `printf '%s\\n' "$$" > ${shellQuote(pidFile)}`,
    `printf 'before-failure\\n'`,
    `IFS= read -r _ < ${shellQuote(releaseFifo)}`,
    `printf 'failure-tail\\n'`,
    "exit 7",
  ].join("; ");
  const execution = fixture.extension.tools.get("bash")!.definition.execute(
    "failure",
    { command },
    fixture.controller.signal,
    undefined,
    fakeToolContext(root),
  ) as Promise<TestToolResult>;

  await waitForPath(pidFile);
  assert.deepEqual(fixture.session.input()!("\x02"), { consume: true });
  assert.equal(
    (await withDeadline(execution, "failure handoff", 1_000)).terminate,
    true,
  );
  await writeFile(releaseFifo, "continue\n");
  await withDeadline(fixture.delivered.promise, "failure completion");

  const sent = fixture.sent[0].message as {
    content: string;
    details: { status: string; exitCode: number };
  };
  assert.equal(sent.details.status, "failed");
  assert.equal(sent.details.exitCode, 7);
  assert.match(sent.content, /failure-tail/);
});

test("one Ctrl+B detaches two concurrent Bash calls", async (t) => {
  const fixture = await startedSession(t);
  const root = mkdtempSync(join(tmpdir(), "pi-background-bash-parallel-"));
  t.after(async () => {
    await fixture.shutdown();
    rmSync(root, { recursive: true, force: true });
  });
  const starts = [1, 2].map((id) => ({
    id,
    marker: join(root, `pid-${id}`),
    fifo: join(root, `release-${id}`),
  }));
  for (const item of starts) makeFifo(item.fifo);

  const tool = fixture.extension.tools.get("bash")!.definition;
  const executions = starts.map((item) =>
    tool.execute(
      `parallel-${item.id}`,
      {
        command: [
          `printf '%s\\n' "$$" > ${shellQuote(item.marker)}`,
          `printf 'before-${item.id}\\n'`,
          `IFS= read -r _ < ${shellQuote(item.fifo)}`,
          `printf 'after-${item.id}\\n'`,
        ].join("; "),
      },
      fixture.controller.signal,
      undefined,
      fakeToolContext(root),
    ) as Promise<TestToolResult>,
  );

  await Promise.all(starts.map((item) => waitForPath(item.marker)));
  assert.deepEqual(fixture.session.input()!("\x02"), { consume: true });
  const handoffs = await Promise.all(
    executions.map((value, index) =>
      withDeadline(value, `parallel handoff ${index + 1}`, 1_000),
    ),
  );
  assert.deepEqual(
    handoffs.map((value) => value.terminate),
    [true, true],
  );

  const twoMessages = deferred<void>();
  fixture.loaded.runtime.sendMessage = (message: unknown, options: unknown) => {
    fixture.sent.push({ message, options });
    if (fixture.sent.length === 2) twoMessages.resolve();
  };
  await Promise.all(
    starts.map((item) => writeFile(item.fifo, "continue\n")),
  );
  await withDeadline(twoMessages.promise, "parallel completions");

  assert.equal(fixture.sent.length, 2);
  const bodies = fixture.sent.map(
    (value) => (value.message as { content: string }).content,
  );
  assert.ok(bodies.some((body) => body.includes("after-1")));
  assert.ok(bodies.some((body) => body.includes("after-2")));
});
