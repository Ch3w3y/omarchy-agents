#!/bin/bash
# Removes the My Agents companion scripts. Does not use sudo/pkexec.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"

for script in "$SCRIPT_DIR"/scripts/*; do
  name="$(basename "$script")"
  if [[ -f "$BIN_DIR/$name" ]]; then
    rm -f "$BIN_DIR/$name"
    echo "Removed $BIN_DIR/$name"
  fi
done

echo
echo "Bar widget: run 'omarchy plugin disable daryn.agents' if you enabled it,"
echo "then remove the plugin directory:"
echo "  rm -rf ~/.config/omarchy/plugins/daryn.agents"
echo
read -r -p "Also delete saved usage records and API keys ($HOME/.local/state/omarchy/agents and $HOME/.config/omarchy/agents)? [y/N] " reply
if [[ "$reply" =~ ^[Yy]$ ]]; then
  rm -rf "$HOME/.local/state/omarchy/agents" "$HOME/.config/omarchy/agents"
  echo "Removed saved usage records and API keys."
else
  echo "Left saved usage records and API keys in place."
fi
