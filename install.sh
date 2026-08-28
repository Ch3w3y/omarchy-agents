#!/bin/bash
# Installs the My Agents companion scripts to ~/.local/bin. Does not touch
# pacman/AUR, does not use sudo/pkexec, and does not write anything outside
# $HOME. The panel itself only ever reads JSON records these scripts write to
# ~/.local/state/omarchy/agents/usage/ -- it never runs a provider's API
# directly.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$BIN_DIR"

for script in "$SCRIPT_DIR"/scripts/*; do
  name="$(basename "$script")"
  cp "$script" "$BIN_DIR/$name"
  chmod +x "$BIN_DIR/$name"
  echo "Installed $BIN_DIR/$name"
done

cat <<'EOF'

Next steps:
  1. Enable the bar widget, if you haven't:
       omarchy plugin enable daryn.agents
  2. Claude, Codex, Fireworks come from a signed-in CLI -- nothing else to
     do if you already use one.
  3. OpenRouter, OpenCode Go, and Ollama Cloud each take a pasted API key
     from the gear icon on the panel itself (openrouter.ai, an
     `opencode auth login`, and ollama.com/settings/keys, respectively).
  4. Nous Portal has no plain API key -- sign in from the same gear icon,
     or directly with:
       omarchy-agent-nous-login
  5. Antigravity and Pi need nothing extra; they read local session data
     the moment you've used either one.

A subscription's tab appears on its own once it has something to report --
nothing to enable per-provider beyond what's above.
EOF
