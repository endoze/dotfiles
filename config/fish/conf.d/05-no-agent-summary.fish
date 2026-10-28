# Unofficial Bun preload that stops Claude Code's agent_summary side-requests.
# https://gist.github.com/flamerix-ai/c3905705cc4205e5de3011fa2e74efce
# The `=` form matters: `--preload <path>` breaks other bun subcommands.
set -l hook $HOME/.dotfiles/config/claude/no-agent-summary.js
if not string match -q -- "*--preload=$hook*" "$BUN_OPTIONS"
    set -gx BUN_OPTIONS (string trim -- "$BUN_OPTIONS --preload=$hook")
end
