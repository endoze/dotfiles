import assert from "node:assert/strict";
import { test } from "node:test";
import footer from "../footer.ts";

type Handler = (event: unknown, ctx: FooterContext) => unknown;

type ContextUsage = {
  tokens: number | null;
  contextWindow: number;
  percent: number | null;
};

type FooterContext = ReturnType<typeof createContext>;

function createContext() {
  let usage: ContextUsage = {
    tokens: 55_000,
    contextWindow: 872_000,
    percent: (55_000 / 872_000) * 100,
  };
  let footerFactory: ((tui: { requestRender(): void }) => FooterComponent) | undefined;

  return {
    model: { name: "test-model", contextWindow: 872_000 },
    sessionManager: {
      getHeader: () => ({ timestamp: "2026-01-01T00:00:00.000Z" }),
      getEntries: () => [],
    },
    getContextUsage: () => usage,
    setContextUsage(next: ContextUsage) {
      usage = next;
    },
    ui: {
      theme: { fg: (_color: string, value: string) => value },
      setFooter(factory: (tui: { requestRender(): void }) => FooterComponent) {
        footerFactory = factory;
      },
    },
    renderFooter() {
      assert.ok(footerFactory, "footer factory was installed");
      return footerFactory({ requestRender() {} }).render(200)[1];
    },
  };
}

type FooterComponent = {
  render(width: number): string[];
};

test("renders compact current and maximum context after duration", async () => {
  const handlers = new Map<string, Handler>();
  const pi = {
    on(event: string, handler: Handler) {
      handlers.set(event, handler);
    },
    exec: async () => ({ code: 1, stdout: "", killed: false }),
  };
  const ctx = createContext();

  footer(pi as never);
  await handlers.get("session_start")?.({}, ctx);

  const cases: Array<[ContextUsage, string]> = [
    [{ tokens: 999, contextWindow: 872_000, percent: 0.1 }, "999/872k"],
    [{ tokens: 5_500, contextWindow: 872_000, percent: 0.6 }, "5.5k/872k"],
    [{ tokens: 55_000, contextWindow: 872_000, percent: 6.3 }, "55k/872k"],
    [{ tokens: 1_500_000, contextWindow: 2_000_000, percent: 75 }, "1.5M/2.0M"],
    [{ tokens: null, contextWindow: 872_000, percent: null }, "?/872k"],
  ];

  try {
    for (const [usage, expected] of cases) {
      ctx.setContextUsage(usage);
      assert.match(
        ctx.renderFooter(),
        new RegExp(`0m 0s \\| ${expected.replace("?", "\\?")}$`),
      );
    }
  } finally {
    handlers.get("session_shutdown")?.({}, ctx);
  }
});
