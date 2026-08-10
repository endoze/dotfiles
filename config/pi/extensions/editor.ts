// Input editor customizations: a prompt glyph in the left gutter, and a block
// cursor that goes away while the terminal split is unfocused.
//
// Discovery works the same way as footer.ts: pi auto-loads
// ~/.pi/agent/extensions/*.ts, which is a symlink to config/pi/extensions in
// this repo (see modules/home/common/pi.nix). No settings.json entry is needed.

import {
  CustomEditor,
  type ExtensionAPI,
  type KeybindingsManager,
} from "@earendil-works/pi-coding-agent";
import type { EditorTheme, TUI } from "@earendil-works/pi-tui";

// DECSET 1004. pi's terminal setup arms only bracketed paste and the kitty
// keyboard protocol, so nothing turns focus reporting on and the reports below
// never arrive unless we ask for them ourselves.
const FOCUS_REPORTING_ON = "\x1b[?1004h";
const FOCUS_REPORTING_OFF = "\x1b[?1004l";

// CSI I on focus gained, CSI O on focus lost. Under tmux these only arrive with
// `set -g focus-events on`, which is off by default.
const FOCUS_REPORT = /\x1b\[(I|O)/g;

const GLYPH = "❯";

// Columns the glyph and its trailing space take, on top of editorPaddingX.
const GUTTER_WIDTH = 2;

// The block pi paints under the cursor: the grapheme it sits on, wrapped in
// reverse video by the editor in pi-tui. Non-global on purpose, a rendered
// editor holds at most one, and nothing else in the editor uses SGR 7.
const BLOCK_CURSOR = /\x1b\[7m(.*?)\x1b\[0m/;

export default function (pi: ExtensionAPI) {
  let focused = true;
  let armed = false;
  let activeTui: TUI | undefined;

  pi.on("session_start", (_event, ctx) => {
    // Guards the whole extension, not just the component: rpc/json/print modes
    // have no editor to replace and no terminal to negotiate with.
    if (ctx.mode !== "tui") {
      return;
    }

    process.stdout.write(FOCUS_REPORTING_ON);
    armed = true;

    ctx.ui.onTerminalInput((data) => {
      let last: string | undefined;

      // A report can arrive glued to real keystrokes in one read, so strip it
      // out and hand the remainder on rather than consuming the whole chunk.
      const rest = data.replace(FOCUS_REPORT, (_match, kind: string) => {
        last = kind;

        return "";
      });

      if (last === undefined) {
        return undefined;
      }

      const next = last === "I";

      if (next !== focused) {
        focused = next;
        activeTui?.requestRender();
      }

      return rest === "" ? { consume: true } : { data: rest };
    });

    class GutterEditor extends CustomEditor {
      constructor(
        tui: TUI,
        theme: EditorTheme,
        keybindings: KeybindingsManager,
      ) {
        super(tui, theme, keybindings);

        activeTui = tui;
      }

      // pi pushes editorPaddingX onto whichever editor is installed, both when
      // it swaps ours in and whenever the setting changes, so widening happens
      // here rather than in the constructor, where it would be overwritten.
      // editorPaddingX stays the plain margin; the glyph lives in the columns
      // this adds beyond it.
      override setPaddingX(padding: number): void {
        super.setPaddingX(padding + GUTTER_WIDTH);
      }

      override render(width: number): string[] {
        const lines = super.render(width);

        // [top border, ...content, bottom border, ...autocomplete], so there is
        // no content row to decorate until there are three lines.
        if (lines.length < 3) {
          return lines;
        }

        // Mirrors the editor's own clamp: on a narrow terminal it renders less
        // padding than it was configured with, and overwriting the wider figure
        // would eat real text.
        const maxPadding = Math.max(0, Math.floor((width - 1) / 2));
        const padding = Math.min(this.getPaddingX(), maxPadding);

        // Paint the glyph over the left padding of the topmost content row
        // instead of inserting it, so every width the editor already computed
        // still holds.
        if (padding >= GUTTER_WIDTH) {
          const margin = " ".repeat(padding - GUTTER_WIDTH);
          const glyph = ctx.ui.theme.fg("accent", GLYPH);

          lines[1] = `${margin}${glyph} ${lines[1].slice(padding)}`;
        }

        if (!focused) {
          for (let row = 1; row < lines.length; row++) {
            lines[row] = lines[row].replace(BLOCK_CURSOR, "$1");
          }
        }

        return lines;
      }
    }

    ctx.ui.setEditorComponent(
      (tui, theme, keybindings) => new GutterEditor(tui, theme, keybindings),
    );
  });

  pi.on("session_shutdown", () => {
    if (armed) {
      process.stdout.write(FOCUS_REPORTING_OFF);
      armed = false;
    }

    focused = true;
    activeTui = undefined;
  });
}
