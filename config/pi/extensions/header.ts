// Claude-Code-style startup header.
//
// Discovery: pi auto-loads ~/.pi/agent/extensions/*.ts, which is a symlink to
// config/pi/extensions in this repo (see modules/home/common/pi.nix). No
// settings.json entry is needed. Extensions load via jiti, so this .ts file
// runs as-is with no build step.
//
// setHeader replaces only the logo + keybinding hints block. The
// [Extensions]/[Skills]/[Themes] listing below it is a separate container
// owned by pi; hide that with "quietStartup": true in settings.json.

import type {
  ExtensionAPI,
  ModelRegistry,
  SlashCommandInfo,
  Theme,
} from "@earendil-works/pi-coding-agent";
import { getAgentDir, VERSION } from "@earendil-works/pi-coding-agent";
import type { Api, Model, ModelThinkingLevel } from "@earendil-works/pi-ai";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { existsSync, readdirSync } from "node:fs";
import { homedir } from "node:os";
import { basename, extname, join } from "node:path";

// Three rows of mark, sized to sit left of the text column like the Claude
// Code logo. Every row is padded to the same printable width so the text
// column never shifts; colors are applied per row, so build the rows here
// rather than coloring one blob.
type Logo = (theme: Theme) => string[];

// pi's mascot: eyes over the bar, legs under it.
const MASCOT: Logo = (theme) => {
  // Full block plus a dark half-block reads as a pupil looking sideways.
  const eye = `${theme.fg("text", "█")}${theme.fg("dim", "▌")}`;

  return [
    `   ${eye}  ${eye}  `,
    theme.fg("accent", "▗█████████▖"),
    theme.fg("accent", "   ██  ██  "),
  ];
};

// Plain π, no face.
const GLYPH: Logo = (theme) => [
  theme.fg("accent", " ▗▄▄▄▄▄▄▄▖ "),
  theme.fg("accent", "  ▐█▌▐█▌  "),
  theme.fg("accent", "  ▝█▘▝█▘  "),
];

// Thin serif π: a light bar over tapered legs. Half-blocks lean the legs
// outward, and the quadrant feet keep them off the text baseline.
const SERIF: Logo = (theme) => [
  theme.fg("accent", " ▄▄▄▄▄▄▄▄"),
  theme.fg("accent", "   █▌ ▐█ "),
  theme.fg("accent", "   ▀▘ ▝▀ "),
];

// Swap for MASCOT (eyes over the bar) or GLYPH (solid π).
const LOGO: Logo = SERIF;

const GUTTER = "  ";

function shortenPath(path: string): string {
  const home = homedir();

  return path === home || path.startsWith(home + "/")
    ? `~${path.slice(home.length)}`
    : path;
}

// 1000000 -> "1M", 200000 -> "200K". Anything smaller stays exact, since a
// rounded "0K" would be worse than the raw number.
function formatContextWindow(tokens: number): string {
  if (tokens >= 1_000_000) {
    const millions = tokens / 1_000_000;

    return `${Number.isInteger(millions) ? millions : millions.toFixed(1)}M`;
  }

  if (tokens >= 1_000) {
    return `${Math.round(tokens / 1_000)}K`;
  }

  return String(tokens);
}

// pi exposes no "what extensions are loaded" API to extensions, so mirror the
// auto-discovery in package-manager.js: top-level .ts/.js files and index-file
// directories under the user and project extension dirs. Extensions disabled
// by a settings pattern are not filtered out here.
function discoverExtensionDir(dir: string): string[] {
  if (!existsSync(dir)) {
    return [];
  }

  let entries;

  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch {
    return [];
  }

  const labels: string[] = [];

  for (const entry of entries) {
    if (entry.name.startsWith(".")) {
      continue;
    }

    if (entry.isDirectory()) {
      const hasEntryPoint = ["index.ts", "index.js", "index.mjs"].some((file) =>
        existsSync(join(dir, entry.name, file)),
      );

      if (hasEntryPoint) {
        labels.push(entry.name);
      }

      continue;
    }

    // tsconfig.json and friends share the directory but are not extensions.
    if ([".ts", ".js", ".mjs"].includes(extname(entry.name))) {
      labels.push(extensionLabelFromPath(entry.name));
    }
  }

  return labels;
}

// Package extensions (settings.json "packages") and CLI `-e` extensions live
// outside those dirs, so recover them from the commands they register. For a
// package, sourceInfo.source is the raw settings spec.
// Extensions that register no command stay invisible this way, which is why
// the directory scan runs too.
function commandExtensionLabels(commands: SlashCommandInfo[]): string[] {
  return commands
    .filter((command) => command.source === "extension")
    .map(({ sourceInfo }) =>
      sourceInfo.origin === "package"
        ? packageLabelFromSpec(sourceInfo.source)
        : extensionLabelFromPath(sourceInfo.path),
    );
}

// "npm:@rahularya01/pi-cursor@1.4.29" -> "pi-cursor";
// "git:github.com/obra/superpowers" -> "superpowers"; "npm:pkg" -> "pkg".
function packageLabelFromSpec(spec: string): string {
  const name = basename(spec.replace(/^(npm|git):/, ""));
  // Trailing @version only; index 0 is a leading @scope on an unscoped-path spec.
  const version = name.lastIndexOf("@");

  return version > 0 ? name.slice(0, version) : name;
}

// "…/extensions/footer.ts" -> "footer"; "…/extensions/doom/index.ts" -> "doom".
function extensionLabelFromPath(path: string): string {
  const name = basename(path, extname(path));

  return name === "index" ? basename(join(path, "..")) : name;
}

// Skills surface through getCommands() as "skill:<name>" entries.
function skillLabels(commands: SlashCommandInfo[]): string[] {
  return commands
    .filter((command) => command.source === "skill")
    .map((command) => command.name.replace(/^skill:/, ""));
}

function sortedUnique(values: string[]): string[] {
  return [...new Set(values)].sort((a, b) => a.localeCompare(b));
}

// Greedy fill so a long list becomes several aligned rows instead of one
// truncated row. Width is the room left after the label column.
function wrapItems(items: string[], width: number): string[] {
  const rows: string[] = [];
  let row = "";

  for (const item of items) {
    const candidate = row === "" ? item : `${row}, ${item}`;

    if (row !== "" && visibleWidth(candidate) > width) {
      rows.push(`${row},`);
      row = item;

      continue;
    }

    row = candidate;
  }

  if (row !== "") {
    rows.push(row);
  }

  return rows;
}

export default function (pi: ExtensionAPI) {
  // Extension contexts are per-event snapshots, not live objects: ctx.model and
  // ctx.thinkingLevel are plain fields copied when the event fired. Holding the
  // session_start ctx and reading it from render() would pin the header to the
  // startup model, so the render inputs are mirrored into module state that the
  // model/thinking events refresh.
  let model: Model<Api> | undefined;
  let thinking: ModelThinkingLevel | undefined;
  let cwd = "";
  let extensionDirLabels: string[] = [];

  // getCommands() rebuilds three arrays per call, and render() runs on every
  // frame, so recompute the resource rows only when the command set changes
  // size — /reload, resources_discover, and dynamic command registration all
  // move that count.
  let resourceCache: { size: number; rows: Array<[string, string[]]> } = {
    size: -1,
    rows: [],
  };

  function resourceSections(): Array<[string, string[]]> {
    const commands = pi.getCommands();

    if (commands.length !== resourceCache.size) {
      const sections: Array<[string, string[]]> = [
        [
          "extensions",
          sortedUnique([
            ...extensionDirLabels,
            ...commandExtensionLabels(commands),
          ]),
        ],
        ["skills", sortedUnique(skillLabels(commands))],
      ];

      resourceCache = {
        size: commands.length,
        rows: sections.filter(([, items]) => items.length > 0),
      };
    }

    return resourceCache.rows;
  }

  // Set by the header factory, which is the only place tui is handed to us.
  let requestRender: () => void = () => {};

  // Name of the auth method actually in use for the active model's provider,
  // e.g. "Anthropic (Claude Pro/Max)", "Cursor", "Anthropic API key". Reads
  // provider metadata rather than getProviderAuth(), which is async because it
  // can refresh an OAuth token and so cannot be called from render().
  function authLabel(registry: ModelRegistry): string {
    const current = model;

    if (!current) {
      return "";
    }

    const provider = registry.getProvider(current.provider);
    const display = registry.getProviderDisplayName(current.provider);

    if (registry.isUsingOAuth(current)) {
      return provider?.auth.oauth?.name ?? `${display} OAuth`;
    }

    // The sync status only carries a label for environment-sourced keys
    // (the env var name), so fall back to the provider's api-key method name.
    const status = registry.getProviderAuthStatus(current.provider);

    return status.label ?? provider?.auth.apiKey?.name ?? `${display} API key`;
  }

  pi.on("session_start", async (_event, ctx) => {
    if (ctx.mode !== "tui") {
      return;
    }

    model = ctx.model;
    thinking = ctx.thinkingLevel ?? pi.getThinkingLevel();
    cwd = ctx.cwd;

    // Project extensions only load once the project is trusted, so listing that
    // directory untrusted would advertise code pi refused to run. Scanned once
    // per session: the set cannot change without a reload, which re-fires this.
    extensionDirLabels = [
      ...discoverExtensionDir(join(getAgentDir(), "extensions")),
      ...(ctx.isProjectTrusted()
        ? discoverExtensionDir(join(ctx.cwd, ".pi", "extensions"))
        : []),
    ];
    resourceCache = { size: -1, rows: [] };

    // The registry is a live facade over the session runtime, unlike the
    // snapshot fields around it, so it is safe to hold across renders.
    const registry = ctx.modelRegistry;

    ctx.ui.setHeader((tui, theme) => {
      requestRender = () => tui.requestRender();

      const titleLine = (): string =>
        `${theme.bold(theme.fg("accent", "Pi"))} ${theme.fg("text", `v${VERSION}`)}`;

      const modelLine = (): string => {
        if (!model) {
          return theme.fg("dim", "no model");
        }

        const context = `(${formatContextWindow(model.contextWindow)} context)`;

        // "off" is a real thinking level for reasoning models and means the
        // effort clause should disappear, same as for a non-reasoning model.
        const effort =
          model.reasoning && thinking && thinking !== "off"
            ? ` with ${thinking} effort`
            : "";

        const head = theme.fg("text", `${model.name} ${context}${effort}`);
        const auth = authLabel(registry);

        return auth === ""
          ? head
          : `${head}${theme.fg("dim", " · ")}${theme.fg("muted", auth)}`;
      };

      const cwdLine = (): string => theme.fg("dim", shortenPath(cwd));

      // Rows under the logo, aligned to the same text column: a dim label,
      // then the comma-separated names wrapped to the remaining width.
      const resourceLines = (indent: number, width: number): string[] => {
        const sections = resourceSections();

        if (sections.length === 0) {
          return [];
        }

        const labelWidth = Math.max(...sections.map(([label]) => label.length));
        const pad = " ".repeat(indent);
        const room = Math.max(8, width - indent - labelWidth - 2);

        return sections.flatMap(([label, items]) =>
          wrapItems(items, room).map((row, index) => {
            const gutter =
              index === 0 ? label.padEnd(labelWidth) : " ".repeat(labelWidth);

            return truncateToWidth(
              `${pad}${theme.fg("dim", gutter)}  ${theme.fg("muted", row)}`,
              width,
            );
          }),
        );
      };

      return {
        render(width: number): string[] {
          const text = [titleLine(), modelLine(), cwdLine()];
          const art = LOGO(theme);
          const indent = visibleWidth(art[0] ?? "") + GUTTER.length;

          return [
            "",
            ...art.map((row, index) =>
              truncateToWidth(`${row}${GUTTER}${text[index] ?? ""}`, width),
            ),
            ...resourceLines(indent, width),
            "",
          ];
        },
        invalidate() {},
      };
    });
  });

  // Ctrl+P cycling, /model, and session restore all land here.
  pi.on("model_select", async (event, ctx) => {
    model = event.model;
    // Thinking level is per model, so re-read it rather than trusting the
    // value the previous model was using.
    thinking = ctx.thinkingLevel ?? pi.getThinkingLevel();

    requestRender();
  });

  pi.on("thinking_level_select", async (event) => {
    thinking = event.level;

    requestRender();
  });

  pi.registerCommand("builtin-header", {
    description: "Restore pi's built-in startup header",
    handler: async (_args, ctx) => {
      ctx.ui.setHeader(undefined);
      ctx.ui.notify("Built-in header restored", "info");
    },
  });
}
