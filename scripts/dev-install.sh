#!/usr/bin/env bash
# Load the docs plugin locally for development, without installing from a marketplace.
# Usage: ./scripts/dev-install.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_DIR="$SCRIPT_DIR/plugins/docs"

if [[ ! -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ]]; then
  echo "❌ plugin.json not found at $PLUGIN_DIR/.claude-plugin/" >&2
  exit 1
fi

echo "Launching Claude Code with the docs plugin loaded from:"
echo "  $PLUGIN_DIR"
echo ""
echo "Inside the session, try:  /docs:check   (or /docs:init, /docs:update)"
echo "After editing a skill:    /reload-plugins"
echo ""
exec claude --plugin-dir "$PLUGIN_DIR"
