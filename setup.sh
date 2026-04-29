#!/usr/bin/env bash
# setup.sh — Symlink shared OpenCode agents, skills, and plugins into ~/.config/opencode/
#
# Run once after cloning. Re-run after pulling to pick up newly added files.
# Safe to run multiple times — never overwrites existing non-symlink files.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCODE_DIR="$HOME/.config/opencode"

# ── Colours ────────────────────────────────────────────────────────────────────
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RESET="\033[0m"

info() { echo -e "${GREEN}✔${RESET}  $*"; }
warn() { echo -e "${YELLOW}⚠${RESET}  $*"; }

# ── Ensure target directories exist ───────────────────────────────────────────
mkdir -p "$OPENCODE_DIR/agents"
mkdir -p "$OPENCODE_DIR/skills"
mkdir -p "$OPENCODE_DIR/plugins"

# ── Helper: create a symlink safely ───────────────────────────────────────────
link_item() {
  local src="$1"
  local tgt="$2"

  if [ -L "$tgt" ]; then
    ln -sf "$src" "$tgt"
    info "Updated:  $tgt"
  elif [ -e "$tgt" ]; then
    warn "Skipped (non-symlink already exists): $tgt"
  else
    ln -s "$src" "$tgt"
    info "Linked:   $tgt"
  fi
}

# ── Agents ─────────────────────────────────────────────────────────────────────
echo ""
echo "── Agents ────────────────────────────────────────────────────────────────"
for src in "$SCRIPT_DIR/agents/"*.md; do
  link_item "$src" "$OPENCODE_DIR/agents/$(basename "$src")"
done

# ── Skills ─────────────────────────────────────────────────────────────────────
echo ""
echo "── Skills ────────────────────────────────────────────────────────────────"
for src in "$SCRIPT_DIR/skills/"/*/; do
  link_item "$src" "$OPENCODE_DIR/skills/$(basename "$src")"
done

# ── Plugins ────────────────────────────────────────────────────────────────────
echo ""
echo "── Plugins ───────────────────────────────────────────────────────────────"
for src in "$SCRIPT_DIR/plugins/"*; do
  link_item "$src" "$OPENCODE_DIR/plugins/$(basename "$src")"
done

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
info "Done. Restart OpenCode to pick up any new agents or skills."
echo ""
  echo "  To update: cd $SCRIPT_DIR && git pull"
  echo "  Re-run ./setup.sh only if new agents or skills were added to the repo."
echo ""
